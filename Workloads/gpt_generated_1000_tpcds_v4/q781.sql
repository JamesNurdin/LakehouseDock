SELECT
    s.s_store_name,
    sm_ws.sm_type AS ship_mode_type,
    d.d_year AS return_year,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(ws.ws_net_profit) AS total_web_sales_profit
FROM store s
JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN customer_address ca_cr_refund
  ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN customer_address ca_cr_return
  ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d.d_year = 2002
GROUP BY
    s.s_store_name,
    sm_ws.sm_type,
    d.d_year
ORDER BY
    d.d_year DESC,
    total_store_return_loss DESC
LIMIT 100
