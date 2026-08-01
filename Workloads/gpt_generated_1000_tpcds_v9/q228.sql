WITH joined_data AS (
   SELECT
     w.w_warehouse_name,
     p.p_promo_name,
     d_sold.d_weekend,
     p.p_discount_active,
     ws.ws_net_profit,
     ws.ws_quantity,
     COALESCE(wr.wr_net_loss, 0) AS wr_net_loss,
     COALESCE(wr.wr_return_quantity, 0) AS wr_return_quantity
   FROM web_sales ws
   JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
   JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
   JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
   LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
   LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
   LEFT JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
   LEFT JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
   LEFT JOIN web_page wp_return ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
   JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
                     AND inv.inv_date_sk = d_sold.d_date_sk
),
aggregated AS (
   SELECT
     w_warehouse_name,
     p_promo_name,
     d_weekend,
     p_discount_active,
     SUM(ws_net_profit) AS total_net_profit,
     SUM(wr_net_loss) AS total_return_loss,
     SUM(ws_net_profit) - SUM(wr_net_loss) AS net_total,
     SUM(ws_quantity) AS total_quantity_sold,
     SUM(wr_return_quantity) AS total_quantity_returned
   FROM joined_data
   GROUP BY
     w_warehouse_name,
     p_promo_name,
     d_weekend,
     p_discount_active
)
SELECT
  w_warehouse_name,
  p_promo_name,
  CASE WHEN d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  CASE WHEN p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS discount_flag,
  total_net_profit,
  total_return_loss,
  net_total,
  total_quantity_sold,
  total_quantity_returned,
  RANK() OVER (ORDER BY net_total DESC) AS profit_rank
FROM aggregated
ORDER BY net_total DESC
LIMIT 100
