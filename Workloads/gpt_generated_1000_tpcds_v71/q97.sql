WITH max_inv AS (
    SELECT inv_item_sk, MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    d_sales.d_year AS sales_year,
    sm.sm_type AS ship_type,
    i.i_category AS item_category,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_refund
  ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN warehouse w_ret
  ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_store_ret
  ON sr.sr_returned_date_sk = d_store_ret.d_date_sk
JOIN time_dim t_store_ret
  ON sr.sr_return_time_sk = t_store_ret.t_time_sk
JOIN reason r_store
  ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_web_sales
  ON ws.ws_sold_date_sk = d_web_sales.d_date_sk
JOIN time_dim t_web_sales
  ON ws.ws_sold_time_sk = t_web_sales.t_time_sk
JOIN ship_mode sm_web
  ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN warehouse w_web
  ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_web_ret
  ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
JOIN time_dim t_web_ret
  ON wr.wr_returned_time_sk = t_web_ret.t_time_sk
JOIN reason r_web_ret
  ON wr.wr_reason_sk = r_web_ret.r_reason_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN date_dim d_site_open
  ON we.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON we.web_close_date_sk = d_site_close.d_date_sk
LEFT JOIN max_inv mi
  ON i.i_item_sk = mi.inv_item_sk
GROUP BY GROUPING SETS (
    (d_sales.d_year, sm.sm_type),
    (i.i_category),
    ()
)
ORDER BY sales_year DESC, ship_type
LIMIT 100
