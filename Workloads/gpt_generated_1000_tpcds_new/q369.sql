WITH ca_sample AS (
  SELECT *
  FROM customer_address
  TABLESAMPLE BERNOULLI (10)
),
sr_sample AS (
  SELECT *
  FROM store_returns
  TABLESAMPLE BERNOULLI (10)
),
joined AS (
  SELECT
    ca.ca_state,
    ca.ca_zip,
    ca.ca_city,
    ca.ca_address_sk,
    sr.sr_customer_sk,
    sr.sr_return_amt,
    sr.sr_return_amt_inc_tax,
    sr.sr_return_tax,
    sr.sr_return_ship_cost,
    CASE
      WHEN sr.sr_return_amt > 1000 THEN 'high'
      WHEN sr.sr_return_amt IS NULL THEN 'unknown'
      ELSE 'low'
    END AS return_category,
    ARRAY[ca.ca_street_name, ca.ca_street_type] AS addr_parts
  FROM sr_sample sr
  FULL OUTER JOIN ca_sample ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE
    ca.ca_state = 'CA'
    AND ca.ca_city = 'Lincoln'
    AND (sr.sr_return_ship_cost > 500 OR sr.sr_return_ship_cost IS NULL)
)
SELECT
  j.ca_state,
  j.return_category,
  part AS address_component,
  SUM(j.sr_return_amt_inc_tax) AS total_return_inc_tax,
  AVG(j.sr_return_tax) AS avg_return_tax,
  COUNT(DISTINCT j.sr_customer_sk) AS distinct_customers,
  COUNT(DISTINCT j.ca_zip) AS distinct_zip_codes,
  MIN(j.sr_return_ship_cost) AS min_ship_cost,
  MAX(j.sr_return_ship_cost) AS max_ship_cost
FROM joined j
LEFT JOIN UNNEST(j.addr_parts) AS t (part) ON TRUE
GROUP BY
  j.ca_state,
  j.return_category,
  part
ORDER BY total_return_inc_tax DESC
LIMIT 100
