WITH base AS (
  SELECT
    cr.cr_returning_customer_sk,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    d.d_date,
    d.d_current_year,
    ca_ret.ca_city,
    ca_ret.ca_state,
    ca_ret.ca_suite_number,
    sm.sm_ship_mode_id,
    sm.sm_code,
    ib.ib_lower_bound,
    hd_ret.hd_vehicle_count,
    ca_ref.ca_location_type
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib ON hd_ret.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    AND d.d_current_year = 'Y'
    AND ca_ret.ca_city = 'Pleasant Valley'
    AND ca_ref.ca_location_type = 'single family'
    AND sm.sm_code = 'AIR'
    AND ib.ib_lower_bound >= 50000
    AND hd_ret.hd_vehicle_count >= 2
),

distinct_returns AS (
  SELECT DISTINCT
    cr_returning_customer_sk,
    cr_return_amount,
    cr_net_loss,
    cr_return_quantity,
    ca_city,
    sm_ship_mode_id,
    ca_suite_number
  FROM base
),

expanded AS (
  SELECT
    dr.*, 
    suite_part
  FROM distinct_returns dr
  CROSS JOIN UNNEST(split(dr.ca_suite_number, ' ')) AS t (suite_part)
),

aggregated AS (
  SELECT
    ca_city,
    sm_ship_mode_id,
    suite_part,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cr_returning_customer_sk) AS distinct_customers
  FROM expanded
  GROUP BY ca_city, sm_ship_mode_id, suite_part
  HAVING SUM(cr_return_amount) > 1000
)
SELECT
  ca_city,
  sm_ship_mode_id,
  suite_part,
  total_return_amount,
  total_net_loss,
  avg_return_quantity,
  distinct_customers,
  RANK() OVER (PARTITION BY ca_city ORDER BY total_return_amount DESC) AS city_return_rank
FROM aggregated
ORDER BY city_return_rank, total_return_amount DESC
LIMIT 100
