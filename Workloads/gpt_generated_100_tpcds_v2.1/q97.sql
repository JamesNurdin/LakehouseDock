WITH order_metrics AS (
  SELECT
    wsales.ws_order_number,
    w.w_warehouse_sk,
    w.w_state,
    d.d_year AS sales_year,
    p.p_channel_tv,
    SUM(wsales.ws_net_profit) AS order_net_profit,
    SUM(COALESCE(sreturns.sr_net_loss, 0) + COALESCE(creturns.cr_net_loss, 0) + COALESCE(wreturns.wr_net_loss, 0)) AS order_return_net_loss,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS order_inventory_qty
  FROM web_sales wsales
  JOIN date_dim d ON wsales.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON wsales.ws_sold_time_sk = t.t_time_sk
  JOIN warehouse w ON wsales.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON wsales.ws_promo_sk = p.p_promo_sk
  JOIN customer c ON wsales.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON wsales.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON wsales.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wsales.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws ON wsales.ws_web_site_sk = ws.web_site_sk
  LEFT JOIN store_returns sreturns
    ON sreturns.sr_returned_date_sk = d.d_date_sk
   AND sreturns.sr_return_time_sk = t.t_time_sk
   AND sreturns.sr_customer_sk = c.c_customer_sk
   AND sreturns.sr_hdemo_sk = hd.hd_demo_sk
   AND sreturns.sr_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns creturns
    ON creturns.cr_returned_date_sk = d.d_date_sk
   AND creturns.cr_returned_time_sk = t.t_time_sk
   AND creturns.cr_refunded_customer_sk = c.c_customer_sk
   AND creturns.cr_refunded_hdemo_sk = hd.hd_demo_sk
   AND creturns.cr_refunded_addr_sk = ca.ca_address_sk
   AND creturns.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = creturns.cr_catalog_page_sk
  LEFT JOIN web_returns wreturns
    ON wreturns.wr_returned_date_sk = d.d_date_sk
   AND wreturns.wr_returned_time_sk = t.t_time_sk
   AND wreturns.wr_refunded_customer_sk = c.c_customer_sk
   AND wreturns.wr_refunded_hdemo_sk = hd.hd_demo_sk
   AND wreturns.wr_refunded_addr_sk = ca.ca_address_sk
   AND wreturns.wr_item_sk = wsales.ws_item_sk
   AND wreturns.wr_web_page_sk = wp.wp_web_page_sk
   AND wreturns.wr_order_number = wsales.ws_order_number
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND p.p_channel_tv = 'Y'
    AND w.w_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY wsales.ws_order_number, w.w_warehouse_sk, w.w_state, d.d_year, p.p_channel_tv
)
SELECT
  sales_year,
  w_state,
  p_channel_tv,
  COUNT(*) AS num_orders,
  SUM(order_net_profit) AS total_net_profit,
  SUM(order_return_net_loss) AS total_return_net_loss,
  SUM(order_inventory_qty) AS total_inventory_qty,
  CASE WHEN SUM(order_net_profit) > SUM(order_return_net_loss)
       THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM order_metrics
GROUP BY sales_year, w_state, p_channel_tv
HAVING SUM(order_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
