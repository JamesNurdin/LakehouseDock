WITH sales_returns AS (
  SELECT
    t.t_time_sk,
    t.t_meal_time,
    t.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    AVG(cr.cr_fee) AS avg_return_fee,
    (
      SELECT MAX(cr2.cr_return_amount)
      FROM catalog_returns cr2
      WHERE cr2.cr_returned_time_sk = t.t_time_sk
    ) AS max_return_amount
  FROM time_dim t
  JOIN store_sales ss ON t.t_time_sk = ss.ss_sold_time_sk
  JOIN catalog_returns cr ON t.t_time_sk = cr.cr_returned_time_sk
  WHERE
    t.t_meal_time = 'lunch'
    AND ss.ss_wholesale_cost > 30.00
    AND cr.cr_fee < 50.00
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr_ex
      WHERE cr_ex.cr_returned_time_sk = t.t_time_sk
        AND cr_ex.cr_fee > 200.00
    )
  GROUP BY t.t_time_sk, t.t_meal_time, t.t_hour
),

sales_returns_alt AS (
  SELECT
    t.t_time_sk,
    t.t_meal_time,
    t.t_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    AVG(cr.cr_fee) AS avg_return_fee,
    (
      SELECT MAX(cr2.cr_return_amount)
      FROM catalog_returns cr2
      WHERE cr2.cr_returned_time_sk = t.t_time_sk
    ) AS max_return_amount
  FROM time_dim t
  JOIN store_sales ss ON t.t_time_sk = ss.ss_sold_time_sk
  JOIN catalog_returns cr ON t.t_time_sk = cr.cr_returned_time_sk
  WHERE
    t.t_meal_time = 'dinner'
    AND ss.ss_wholesale_cost BETWEEN 25.00 AND 35.00
    AND cr.cr_fee BETWEEN 10.00 AND 80.00
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr_ex
      WHERE cr_ex.cr_returned_time_sk = t.t_time_sk
        AND cr_ex.cr_fee > 200.00
    )
  GROUP BY t.t_time_sk, t.t_meal_time, t.t_hour
)
SELECT
  t_time_sk,
  t_meal_time,
  t_hour,
  total_sales,
  total_returns,
  distinct_items_sold,
  avg_return_fee,
  max_return_amount
FROM sales_returns
UNION ALL
SELECT
  t_time_sk,
  t_meal_time,
  t_hour,
  total_sales,
  total_returns,
  distinct_items_sold,
  avg_return_fee,
  max_return_amount
FROM sales_returns_alt
ORDER BY t_meal_time, t_hour DESC, t_time_sk
