WITH ss AS (
  SELECT
    ss_customer_sk AS customer_sk,
    SUM(ss_net_paid) AS total_paid
  FROM store_sales
  JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
  JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
  WHERE time_dim.t_hour BETWEEN 9 AND 17
    AND customer_demographics.cd_credit_rating = 'Good'
  GROUP BY ss_customer_sk
),
cr AS (
  SELECT
    cr_refunded_customer_sk AS customer_sk,
    SUM(cr_return_amount) AS total_return
  FROM catalog_returns
  JOIN time_dim ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
  JOIN ship_mode ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
  WHERE time_dim.t_hour BETWEEN 9 AND 17
    AND ship_mode.sm_code = 'AIR'
  GROUP BY cr_refunded_customer_sk
),
combined AS (
  SELECT
    COALESCE(ss.customer_sk, cr.customer_sk) AS customer_sk,
    ss.total_paid,
    cr.total_return
  FROM ss
  FULL OUTER JOIN cr ON ss.customer_sk = cr.customer_sk
),
filtered AS (
  SELECT *
  FROM combined
  WHERE customer_sk NOT IN (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_return_amt > 100
  )
),
key_set_a AS (
  SELECT customer_sk FROM ss WHERE total_paid > 5000
),
key_set_b AS (
  SELECT customer_sk FROM cr WHERE total_return > 200
),
key_set_c AS (
  SELECT sr_customer_sk AS customer_sk
  FROM store_returns
  WHERE sr_return_amt > 1000
),
final_keys AS (
  SELECT customer_sk FROM key_set_a
  INTERSECT
  SELECT customer_sk FROM key_set_b
  EXCEPT
  SELECT customer_sk FROM key_set_c
)
SELECT
  customer_sk,
  total_paid,
  total_return
FROM filtered
WHERE customer_sk IN (SELECT customer_sk FROM final_keys)

UNION ALL

SELECT
  ss.customer_sk AS customer_sk,
  ss.total_paid,
  CAST(NULL AS decimal(7,2)) AS total_return
FROM ss
WHERE ss.customer_sk NOT IN (SELECT customer_sk FROM filtered)

ORDER BY total_paid DESC, customer_sk
LIMIT 100
