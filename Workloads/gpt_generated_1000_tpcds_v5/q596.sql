SELECT
    d_cr.d_year,
    sm.sm_type,
    w.w_state,
    COUNT(*) AS total_return_rows,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales_price,
    SUM(wr.wr_return_amt) AS sum_web_return_amount,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss
FROM catalog_returns cr
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
-- connect web_sales through the same ship mode, warehouse and sold date
JOIN web_sales ws
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
 AND ws.ws_sold_date_sk = d_cr.d_date_sk
-- ship date dimension (not used in SELECT but required by join rules)
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
-- web_returns links to web_sales via item and order number
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE d_cr.d_year = 2001
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND ws.ws_quantity > 30
  AND cr.cr_return_amount > 50.00
  AND d_wr.d_month_seq = 12
GROUP BY ROLLUP (d_cr.d_year, sm.sm_type, w.w_state)
ORDER BY d_cr.d_year, sm.sm_type, w.w_state
