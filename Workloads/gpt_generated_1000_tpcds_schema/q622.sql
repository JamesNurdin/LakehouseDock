WITH filtered AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_month,
    c.c_last_review_date,
    ca.ca_state,
    ca.ca_city,
    hd.hd_income_band_sk,
    ib.ib_upper_bound,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_char_count,
    wr.wr_return_amt,
    wr.wr_return_quantity
  FROM customer c
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  JOIN web_returns wr
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE c.c_birth_month = 9
    AND ca.ca_state = 'CA'
    AND ib.ib_upper_bound >= 150000
    AND wp.wp_type = 'product'
    AND wp.wp_char_count > 2000
    AND wr.wr_return_amt > 1000
),
heavy_returns AS (
  SELECT DISTINCT wr.wr_refunded_customer_sk AS c_customer_sk
  FROM web_returns wr
  WHERE wr.wr_return_amt > 5000
),
low_returns AS (
  SELECT DISTINCT wr.wr_refunded_customer_sk AS c_customer_sk
  FROM web_returns wr
  WHERE wr.wr_return_amt < 500
),
target_customers AS (
  SELECT c_customer_sk FROM heavy_returns
  EXCEPT
  SELECT c_customer_sk FROM low_returns
),
region_dim AS (
  SELECT 'NA' AS region UNION ALL SELECT 'EU' AS region
),
income_bounds AS (
  SELECT ib_upper_bound
  FROM income_band
  WHERE ib_upper_bound > 120000
)
SELECT
  f.ca_state,
  f.ib_upper_bound,
  r.region,
  COUNT(DISTINCT f.c_customer_sk) AS num_customers,
  SUM(f.wr_return_amt) AS total_return_amount,
  AVG(f.wr_return_amt) AS avg_return_amount,
  MIN(f.wr_return_amt) AS min_return,
  MAX(f.wr_return_amt) AS max_return,
  lc.max_return_per_customer
FROM filtered f
JOIN target_customers tc
  ON f.c_customer_sk = tc.c_customer_sk
JOIN LATERAL (
   SELECT MAX(wr2.wr_return_amt) AS max_return_per_customer
   FROM web_returns wr2
   WHERE wr2.wr_returning_customer_sk = f.c_customer_sk
) lc ON true
CROSS JOIN region_dim r
CROSS JOIN (SELECT ib_upper_bound FROM income_bounds) ibc
WHERE ibc.ib_upper_bound = f.ib_upper_bound
GROUP BY f.ca_state, f.ib_upper_bound, r.region, lc.max_return_per_customer
HAVING COUNT(*) >= 5
ORDER BY total_return_amount DESC
LIMIT 100
