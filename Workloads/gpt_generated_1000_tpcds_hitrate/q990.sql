WITH filtered_sales AS (
  SELECT ss.*, td.t_sub_shift, td.t_hour, td.t_minute
  FROM store_sales ss
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE ss.ss_ext_tax > 10
    AND ss.ss_ext_tax < 250
    AND ss.ss_cdemo_sk IN (1023064, 781292)
    AND ss.ss_coupon_amt > 0
    AND td.t_hour BETWEEN 9 AND 17
    AND td.t_minute IN (14, 19)
    AND td.t_sub_shift = 'morning'
),
agg AS (
  SELECT
    t_sub_shift,
    t_hour,
    COUNT(*) AS sales_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_paid) AS avg_net_paid,
    MIN(ss_ext_tax) AS min_tax,
    MAX(ss_ext_tax) AS max_tax,
    SUM(ss_ext_sales_price) / COUNT(*) AS avg_sales_per_txn,
    CASE
      WHEN SUM(ss_ext_sales_price) > (SELECT AVG(ss_ext_sales_price) FROM store_sales) THEN 'above_avg'
      ELSE 'below_avg'
    END AS sales_category
  FROM filtered_sales
  GROUP BY t_sub_shift, t_hour
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY t_sub_shift ORDER BY total_sales DESC) AS rn
  FROM agg
)
SELECT
  t_sub_shift,
  t_hour,
  sales_cnt,
  total_sales,
  avg_net_paid,
  min_tax,
  max_tax,
  avg_sales_per_txn,
  sales_category,
  rn
FROM ranked
WHERE rn <= 3
ORDER BY t_sub_shift, rn
