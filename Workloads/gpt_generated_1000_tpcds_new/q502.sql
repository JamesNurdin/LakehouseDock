-- goal: Identify the most profitable web sites by fiscal year, focusing on orders that appear in a specific EXCEPT set and also in an INTERSECT set, while expanding a derived array column for detailed analysis.
WITH
  -- Create an array column per order and explode it
  sales_array AS (
    SELECT
      ws_order_number,
      ws_sold_date_sk,
      ARRAY[ws_quantity, ws_net_paid] AS qty_paid_arr
    FROM web_sales
  ),
  unnested_sales AS (
    SELECT
      sa.ws_order_number,
      sa.ws_sold_date_sk,
      metric
    FROM sales_array sa
    CROSS JOIN UNNEST(sa.qty_paid_arr) AS t(metric)
  ),
  -- Sets for set operations
  order_set_a AS (
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 5
  ),
  order_set_b AS (
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 1000
  ),
  except_orders AS (
    SELECT ws_order_number FROM order_set_a
    EXCEPT
    SELECT ws_order_number FROM order_set_b
  ),
  intersect_orders AS (
    SELECT ws_order_number FROM order_set_a
    INTERSECT
    SELECT ws_order_number FROM order_set_b
  )
SELECT
  ws_site.web_name,
  d_sold.d_year,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_net_profit) AS avg_profit,
  CASE
    WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH'
    ELSE 'MEDIUM'
  END AS profit_category,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  COUNT(DISTINCT us.metric) AS metric_cnt
FROM web_sales ws
FULL OUTER JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
INNER JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
INNER JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
INNER JOIN date_dim d_open
  ON ws_site.web_open_date_sk = d_open.d_date_sk
INNER JOIN date_dim d_close
  ON ws_site.web_close_date_sk = d_close.d_date_sk
INNER JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
INNER JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
LEFT JOIN unnested_sales us
  ON ws.ws_order_number = us.ws_order_number
WHERE ws.ws_order_number IN (SELECT ws_order_number FROM except_orders)
  AND EXISTS (SELECT 1 FROM intersect_orders io WHERE io.ws_order_number = ws.ws_order_number)
GROUP BY ws_site.web_name, d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
