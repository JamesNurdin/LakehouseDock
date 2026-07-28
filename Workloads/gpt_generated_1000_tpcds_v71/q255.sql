WITH refunded AS (
  SELECT
    ca.ca_state AS state,
    hd.hd_vehicle_count AS vehicle_count,
    sum(cr.cr_return_amount) AS total_return_amount,
    avg(cr.cr_fee) AS avg_fee,
    count(*) AS return_cnt,
    'refunded' AS return_type
  FROM catalog_returns cr
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE cr.cr_fee > 30
    AND ca.ca_state = 'CA'
  GROUP BY ca.ca_state, hd.hd_vehicle_count
),
returning AS (
  SELECT
    ca.ca_state AS state,
    hd.hd_vehicle_count AS vehicle_count,
    sum(cr.cr_return_amount) AS total_return_amount,
    avg(cr.cr_fee) AS avg_fee,
    count(*) AS return_cnt,
    'returning' AS return_type
  FROM catalog_returns cr
  JOIN household_demographics hd
    ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cr.cr_returning_addr_sk = ca.ca_address_sk
  WHERE hd.hd_dep_count >= 5
    AND EXISTS (
      SELECT 1
      FROM customer_address ca2
      WHERE ca2.ca_county = ca.ca_county
        AND ca2.ca_state = ca.ca_state
        AND ca2.ca_suite_number = 'Suite A'
    )
  GROUP BY ca.ca_state, hd.hd_vehicle_count
)
SELECT
  state,
  vehicle_count,
  total_return_amount,
  avg_fee,
  return_cnt,
  return_type
FROM (
  SELECT state, vehicle_count, total_return_amount, avg_fee, return_cnt, return_type FROM refunded
  UNION ALL
  SELECT state, vehicle_count, total_return_amount, avg_fee, return_cnt, return_type FROM returning
) AS combined
ORDER BY total_return_amount DESC, state, vehicle_count
LIMIT 100
