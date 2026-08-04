WITH
  sales_base AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_quantity AS quantity,
      ss.ss_sales_price AS amount,
      CAST(NULL AS varchar) AS reason_desc,
      CAST(NULL AS integer) AS catalog_number,
      CAST(NULL AS varchar) AS warehouse_name,
      t_s.t_hour AS hour,
      ARRAY[ss.ss_quantity] AS qty_arr
    FROM store_sales ss
    JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
    JOIN customer c_s ON ss.ss_customer_sk = c_s.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c_s.c_customer_sk
  ),
  returns_base AS (
    SELECT
      cr.cr_returning_customer_sk AS customer_sk,
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_return_quantity AS quantity,
      cr.cr_return_amount AS amount,
      r.r_reason_desc AS reason_desc,
      cp.cp_catalog_number AS catalog_number,
      w.w_warehouse_name AS warehouse_name,
      t_r.t_hour AS hour,
      ARRAY[cr.cr_return_quantity] AS qty_arr
    FROM catalog_returns cr
    JOIN time_dim t_r ON cr.cr_returned_time_sk = t_r.t_time_sk
    JOIN customer c_r ON cr.cr_returning_customer_sk = c_r.c_customer_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  ),
  union_all AS (
    SELECT * FROM sales_base
    UNION DISTINCT
    SELECT * FROM returns_base
  ),
  intersect_customers AS (
    SELECT customer_sk FROM (SELECT DISTINCT customer_sk FROM sales_base) s
    INTERSECT
    SELECT customer_sk FROM (SELECT DISTINCT customer_sk FROM returns_base) r
  ),
  except_customers AS (
    SELECT customer_sk FROM (SELECT DISTINCT customer_sk FROM sales_base) s
    EXCEPT
    SELECT customer_sk FROM (SELECT DISTINCT customer_sk FROM returns_base) r
  )
SELECT
  ua.customer_sk,
  ua.reason_desc,
  ua.warehouse_name,
  ua.catalog_number,
  ua.hour,
  SUM(ua.amount) AS total_amount,
  COUNT(DISTINCT ua.date_sk) AS distinct_dates,
  SUM(qt.qty_element) AS total_quantity,
  lateral_q.qty_sum
FROM union_all ua
CROSS JOIN UNNEST(ua.qty_arr) AS qt(qty_element)
CROSS JOIN LATERAL (
  SELECT SUM(qty) AS qty_sum FROM UNNEST(ua.qty_arr) AS t(qty)
) AS lateral_q
WHERE ua.customer_sk IN (SELECT customer_sk FROM intersect_customers)
  AND ua.customer_sk NOT IN (SELECT customer_sk FROM except_customers)
GROUP BY
  ua.customer_sk,
  ua.reason_desc,
  ua.warehouse_name,
  ua.catalog_number,
  ua.hour,
  lateral_q.qty_sum
ORDER BY total_amount DESC
LIMIT 100
