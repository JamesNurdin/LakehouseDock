WITH
  agg_returns AS (
    SELECT
      cr_returning_customer_sk,
      cr_returned_time_sk,
      SUM(cr_return_amount)            AS sum_return_amount,
      SUM(cr_return_quantity)          AS sum_return_qty,
      AVG(cr_fee)                      AS avg_fee,
      COUNT(*)                         AS cnt_returns,
      MAX(cr_return_amount)            AS max_return_amount
    FROM catalog_returns
    WHERE cr_returned_time_sk IN (
            SELECT t_time_sk
            FROM time_dim
            WHERE t_hour BETWEEN 9 AND 17
              AND t_meal_time = 'LUNCH'
          )
      AND cr_return_amount > 50
      AND cr_fee > 10
      AND cr_return_tax > 0
      AND cr_return_ship_cost < 100
    GROUP BY cr_returning_customer_sk, cr_returned_time_sk
  ),
  full_customers AS (
    SELECT
      COALESCE(a.cr_returning_customer_sk, c.c_customer_sk) AS customer_sk,
      a.cr_returned_time_sk,
      a.sum_return_amount,
      a.sum_return_qty,
      a.avg_fee,
      a.cnt_returns,
      a.max_return_amount,
      c.c_birth_year,
      c.c_preferred_cust_flag
    FROM agg_returns a
    FULL OUTER JOIN customer c
      ON a.cr_returning_customer_sk = c.c_customer_sk
  ),
  returning_keys AS (
    SELECT DISTINCT cr_returning_customer_sk AS cust_sk FROM catalog_returns
  ),
  refunded_keys AS (
    SELECT DISTINCT cr_refunded_customer_sk AS cust_sk FROM catalog_returns
  ),
  common_customers AS (
    SELECT cust_sk FROM returning_keys
    INTERSECT
    SELECT cust_sk FROM refunded_keys
  ),
  small_times AS (
    SELECT t_time_sk, t_time_id
    FROM time_dim
    WHERE t_hour = 12
    LIMIT 5
  ),
  buckets AS (
    SELECT 1 AS bucket UNION ALL SELECT 2 UNION ALL SELECT 3
  ),
  scalar_avg AS (
    SELECT AVG(cr_return_amount) AS overall_avg_return
    FROM catalog_returns
    WHERE cr_return_amount > 0
  )
SELECT
  fc.customer_sk,
  fc.c_birth_year,
  fc.c_preferred_cust_flag,
  td.t_time_id,
  b.bucket,
  fc.sum_return_amount,
  fc.cnt_returns,
  CASE
    WHEN fc.sum_return_amount > (SELECT overall_avg_return FROM scalar_avg) THEN 'HIGH'
    ELSE 'LOW'
  END AS amount_category,
  MIN(fc.max_return_amount) OVER (PARTITION BY fc.customer_sk) AS min_max_return_amount
FROM full_customers fc
JOIN time_dim td
  ON fc.cr_returned_time_sk = td.t_time_sk
JOIN common_customers cc
  ON fc.customer_sk = cc.cust_sk
CROSS JOIN small_times st
CROSS JOIN buckets b
WHERE td.t_second IN (19, 1, 7)
  AND fc.c_preferred_cust_flag = 'Y'
  AND fc.c_birth_year BETWEEN 1960 AND 1990
ORDER BY fc.sum_return_amount DESC
LIMIT 100
