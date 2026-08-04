WITH
  cust_agg AS (
    SELECT
      c_current_addr_sk,
      COUNT(*) AS cust_cnt,
      AVG(c_birth_year) AS avg_birth_year,
      MIN(c_birth_year) AS min_birth_year,
      MAX(c_birth_year) AS max_birth_year
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_last_review_date > 2452500
      AND c_birth_month = 5
    GROUP BY c_current_addr_sk
  ),
  intersect_keys AS (
    SELECT c_current_addr_sk FROM tpcds.customer WHERE c_birth_year = 1980
    INTERSECT
    SELECT c_current_addr_sk FROM tpcds.customer WHERE c_current_hdemo_sk IS NOT NULL
  ),
  scalar_offset AS (
    SELECT AVG(ca_gmt_offset) AS avg_offset FROM tpcds.customer_address
  )
SELECT
  ca.ca_address_sk,
  ca.ca_city,
  ca.ca_state,
  ca.ca_country,
  ca.ca_gmt_offset,
  ca.ca_location_type,
  ca_agg.cust_cnt,
  ca_agg.avg_birth_year,
  ca_agg.min_birth_year,
  ca_agg.max_birth_year,
  loc_element
FROM tpcds.customer_address ca
JOIN cust_agg ca_agg
  ON ca.ca_address_sk = ca_agg.c_current_addr_sk
JOIN intersect_keys ik
  ON ca.ca_address_sk = ik.c_current_addr_sk
CROSS JOIN scalar_offset so
CROSS JOIN UNNEST(ARRAY[ca.ca_state, ca.ca_country]) AS t(loc_element)
WHERE ca.ca_gmt_offset > so.avg_offset
  AND ca.ca_location_type IN ('apartment', 'condo')
  AND EXISTS (
    SELECT 1 FROM tpcds.customer c
    WHERE c.c_current_addr_sk = ca.ca_address_sk
      AND c.c_first_shipto_date_sk = 2449391
  )
ORDER BY ca_agg.cust_cnt DESC, ca.ca_gmt_offset ASC
LIMIT 100
