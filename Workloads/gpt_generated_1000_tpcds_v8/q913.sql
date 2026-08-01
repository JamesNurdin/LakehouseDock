WITH
  filtered_returns AS (
    SELECT
      sr.sr_addr_sk,
      sr.sr_return_amt_inc_tax,
      sr.sr_return_quantity,
      sr.sr_store_credit,
      sr.sr_reversed_charge,
      sr.sr_net_loss,
      ca.ca_county,
      ca.ca_state,
      ca.ca_zip,
      ca.ca_gmt_offset
    FROM store_returns sr
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_county IN ('Madison County','Richland County','Barry County','Noxubee County')
      AND ca.ca_street_type = 'Avenue'
      AND sr.sr_return_amt_inc_tax > 50
      AND sr.sr_return_quantity >= 1
  ),
  aggregate_by_region AS (
    SELECT
      ca_county,
      ca_state,
      SUM(sr_return_amt_inc_tax) AS total_return_amt,
      SUM(sr_return_quantity) AS total_quantity,
      COUNT(*) AS return_cnt,
      AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM filtered_returns
    GROUP BY CUBE (ca_county, ca_state)
  ),
  ranked_regions AS (
    SELECT
      ca_county,
      ca_state,
      total_return_amt,
      total_quantity,
      return_cnt,
      avg_return_amt,
      ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amt DESC) AS rn_state,
      (SELECT COUNT(DISTINCT ca_state) FROM customer_address) AS distinct_state_cnt
    FROM aggregate_by_region
    WHERE total_return_amt IS NOT NULL
  ),
  full_outer_data AS (
    SELECT
      ca.ca_county,
      ca.ca_state,
      sr.sr_return_amt_inc_tax,
      sr.sr_return_quantity,
      sr.sr_store_credit,
      sr.sr_reversed_charge,
      sr.sr_net_loss
    FROM store_returns sr
    FULL OUTER JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE (ca.ca_country = 'United States' OR ca.ca_country IS NULL)
      AND (sr.sr_return_amt_inc_tax IS NULL OR sr.sr_return_amt_inc_tax > 20)
      AND (ca.ca_gmt_offset BETWEEN -5.00 AND 5.00)
      AND (sr.sr_return_quantity IS NOT NULL AND sr.sr_return_quantity <> 0)
  ),
  aggregated_outer AS (
    SELECT
      fo.ca_county,
      fo.ca_state,
      SUM(fo.sr_return_amt_inc_tax) AS total_return_amt,
      SUM(fo.sr_return_quantity) AS total_quantity,
      COUNT(*) AS return_cnt,
      AVG(fo.sr_return_amt_inc_tax) AS avg_return_amt
    FROM full_outer_data fo
    GROUP BY CUBE (fo.ca_county, fo.ca_state)
    HAVING SUM(fo.sr_return_amt_inc_tax) > (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns)
  )
SELECT
  ca_county,
  ca_state,
  total_return_amt,
  total_quantity,
  return_cnt,
  avg_return_amt,
  rn_state,
  distinct_state_cnt
FROM ranked_regions
WHERE rn_state <= 5

UNION DISTINCT

SELECT
  ca_county,
  ca_state,
  total_return_amt,
  total_quantity,
  return_cnt,
  avg_return_amt,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amt DESC) AS rn_state,
  (SELECT COUNT(DISTINCT ca_state) FROM customer_address) AS distinct_state_cnt
FROM aggregated_outer
WHERE ca_county IS NOT NULL

ORDER BY ca_state, total_return_amt DESC
LIMIT 100
