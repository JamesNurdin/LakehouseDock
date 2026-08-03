WITH
  sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  base_fact AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_warehouse_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      d.d_date,
      w.w_city AS w_warehouse_city,
      w.w_warehouse_sq_ft,
      s.s_state
    FROM sampled_ws ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_city IN ('Pleasant Hill', 'Riverside')
      AND w.w_warehouse_sq_ft > 500000
      AND s.s_state = 'CA'
  ),
  catalog_full AS (
    SELECT
      cr.cr_order_number,
      cr.cr_warehouse_sk,
      cr.cr_return_amount,
      cr.cr_fee,
      cr.cr_returned_date_sk,
      w.w_warehouse_sk,
      w.w_city AS cr_warehouse_city,
      r.r_reason_desc
    FROM catalog_returns cr
    FULL OUTER JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
  ),
  intersect_orders AS (
    SELECT cr_order_number AS order_num
    FROM catalog_returns
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
  ),
  combined AS (
    SELECT
      bf.ws_order_number,
      bf.d_date,
      bf.w_warehouse_city,
      bf.w_warehouse_sq_ft,
      bf.ws_quantity,
      bf.ws_net_paid,
      cf.cr_return_amount,
      cf.cr_fee,
      cf.cr_warehouse_city,
      cf.r_reason_desc
    FROM base_fact bf
    LEFT JOIN catalog_full cf
      ON bf.ws_warehouse_sk = cf.w_warehouse_sk
    WHERE bf.ws_order_number IN (SELECT order_num FROM intersect_orders)
      AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = bf.ws_order_number
          AND wr.wr_return_quantity > 0
          AND wr.wr_returned_time_sk BETWEEN 20000 AND 80000
      )
      AND bf.ws_quantity > 0
      AND bf.ws_net_paid > 0
      AND bf.w_warehouse_city <> 'Salem'
      AND bf.w_warehouse_sq_ft BETWEEN 500000 AND 1000000
      AND bf.d_date >= DATE '2001-01-01'
      AND bf.d_date <= DATE '2001-12-31'
      AND bf.w_warehouse_city IN ('Pleasant Hill', 'Riverside')
  )
SELECT
  d_date,
  w_warehouse_city,
  SUM(ws_quantity) AS total_quantity,
  SUM(ws_net_paid) AS total_net_paid,
  SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
  SUM(COALESCE(cr_fee, 0)) AS total_fee,
  COUNT(DISTINCT ws_order_number) AS distinct_orders
FROM combined
GROUP BY ROLLUP (d_date, w_warehouse_city)
ORDER BY total_net_paid DESC
LIMIT 100
