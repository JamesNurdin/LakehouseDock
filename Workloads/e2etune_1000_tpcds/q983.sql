WITH address_counts AS (
  SELECT
    ca_state,
    ca_county,
    COUNT(*) AS addr_cnt,
    AVG(ca_gmt_offset) AS avg_gmt_offset,
    SUM(CASE WHEN ca_street_type = 'Parkway' THEN 1 ELSE 0 END) AS parkway_cnt,
    COUNT(DISTINCT ca_zip) AS distinct_zip_cnt
  FROM customer_address
  WHERE ca_country = 'United States'
    AND ca_zip IN ('86192', '85709', '12477', '88371', '63951')
  GROUP BY ca_state, ca_county
),
ranked_counts AS (
  SELECT
    ca_state,
    ca_county,
    addr_cnt,
    avg_gmt_offset,
    parkway_cnt,
    distinct_zip_cnt,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY addr_cnt DESC) AS rn
  FROM address_counts
)
SELECT
  ca_state,
  ca_county,
  addr_cnt,
  avg_gmt_offset,
  parkway_cnt,
  distinct_zip_cnt,
  CASE
    WHEN avg_gmt_offset > 0 THEN 'East of GMT'
    ELSE 'West of GMT'
  END AS gmt_region
FROM ranked_counts
WHERE rn <= 3
ORDER BY ca_state, addr_cnt DESC
