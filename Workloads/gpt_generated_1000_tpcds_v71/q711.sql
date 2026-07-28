WITH base AS (
  SELECT
    sm.sm_type,
    td.t_hour,
    ss.ss_ext_sales_price,
    cr.cr_refunded_cash
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE
    td.t_am_pm = 'PM'
    AND td.t_second BETWEEN 0 AND 15
    AND sm.sm_type = 'AIR'
    AND cr.cr_refunded_cash > 1000
    AND cr.cr_store_credit < 200
    AND ss.ss_ext_list_price > 1000
    AND ss.ss_quantity >= 1
),
agg AS (
  SELECT
    sm_type,
    t_hour,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS transaction_cnt
  FROM base
  GROUP BY ROLLUP (sm_type, t_hour)
  HAVING SUM(ss_ext_sales_price) > 5000
)
SELECT
  sm_type,
  t_hour,
  total_sales,
  total_refunded_cash,
  transaction_cnt,
  CASE
    WHEN total_sales > (SELECT AVG(ss_ext_sales_price) FROM store_sales) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS sales_category,
  ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY sm_type NULLS LAST, t_hour NULLS LAST
LIMIT 100
