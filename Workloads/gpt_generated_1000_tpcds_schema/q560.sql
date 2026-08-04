/* goal: Compare web sales performance with inventory levels for high‑value orders in 2001, segmented by warehouse, ship mode and price category, while handling returns and missing data. */
WITH
  /* Pre‑aggregate inventory by warehouse and date */
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 300
    GROUP BY inv_warehouse_sk, inv_date_sk
  ),
  /* Orders present in both sales and returns */
  order_numbers_a AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_sales_price > 200
  ),
  order_numbers_b AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 500
  ),
  common_orders AS (
    SELECT ws_order_number AS order_number
    FROM order_numbers_a
    INTERSECT
    SELECT wr_order_number
    FROM order_numbers_b
  ),
  /* Filtered web sales */
  ws_filtered AS (
    SELECT
      ws_sold_date_sk,
      ws_item_sk,
      ws_order_number,
      ws_sales_price,
      ws_coupon_amt,
      ws_ext_sales_price,
      ws_ship_mode_sk,
      ws_warehouse_sk
    FROM web_sales
    WHERE ws_sales_price > 100
      AND ws_coupon_amt < 300
      AND ws_ext_sales_price BETWEEN 1500 AND 10000
      AND ws_order_number IN (SELECT order_number FROM common_orders)
  ),
  /* Filtered web returns */
  wr_filtered AS (
    SELECT
      wr_returned_date_sk,
      wr_item_sk,
      wr_order_number,
      wr_return_amt_inc_tax,
      wr_account_credit,
      wr_return_ship_cost
    FROM web_returns
    WHERE wr_return_amt_inc_tax > 400
      AND wr_account_credit < 200
      AND wr_return_ship_cost BETWEEN 100 AND 600
  ),
  /* Full outer join to keep sales and returns that do not match */
  full_ws_wr AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_order_number,
      ws.ws_sales_price,
      ws.ws_coupon_amt,
      ws.ws_ext_sales_price,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      wr.wr_returned_date_sk,
      wr.wr_return_amt_inc_tax,
      wr.wr_account_credit,
      wr.wr_return_ship_cost
    FROM ws_filtered ws
    FULL OUTER JOIN wr_filtered wr
      ON ws.ws_item_sk = wr.wr_item_sk
     AND ws.ws_order_number = wr.wr_order_number
  )
SELECT
  d.d_year,
  d.d_month_seq,
  w.w_warehouse_name,
  sm.sm_code,
  CASE WHEN full_ws_wr.ws_sales_price > 200 THEN 'High' ELSE 'Low' END AS price_category,
  SUM(full_ws_wr.ws_ext_sales_price) AS total_sales,
  AVG(full_ws_wr.ws_coupon_amt) AS avg_coupon,
  COUNT(DISTINCT full_ws_wr.ws_order_number) AS distinct_orders,
  MIN(full_ws_wr.ws_sales_price) AS min_price,
  MAX(full_ws_wr.ws_sales_price) AS max_price,
  COALESCE(inv.total_qty, 0) AS total_inventory_qty
FROM full_ws_wr
LEFT JOIN date_dim d
  ON full_ws_wr.ws_sold_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm
  ON full_ws_wr.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
  ON full_ws_wr.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
 AND inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq = 3
  AND sm.sm_contract = 'OrDuVy2H'
  AND w.w_state = 'CA'
  AND sm.sm_code IN ('AIR', 'SEA')
GROUP BY
  d.d_year,
  d.d_month_seq,
  w.w_warehouse_name,
  sm.sm_code,
  CASE WHEN full_ws_wr.ws_sales_price > 200 THEN 'High' ELSE 'Low' END,
  COALESCE(inv.total_qty, 0)
UNION
SELECT
  d.d_year,
  d.d_month_seq,
  w.w_warehouse_name,
  sm.sm_code,
  'NoSales' AS price_category,
  0.0 AS total_sales,
  0.0 AS avg_coupon,
  0 AS distinct_orders,
  NULL AS min_price,
  NULL AS max_price,
  COALESCE(inv.total_qty, 0) AS total_inventory_qty
FROM inv_agg inv
JOIN date_dim d
  ON inv.inv_date_sk = d.d_date_sk
JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = (
       SELECT sm_ship_mode_sk
       FROM ship_mode
       WHERE sm_code = 'AIR'
       LIMIT 1
     )
WHERE d.d_year = 2001
  AND d.d_month_seq = 3
  AND w.w_state = 'CA'
  AND sm.sm_contract = 'OrDuVy2H'
LIMIT 100
