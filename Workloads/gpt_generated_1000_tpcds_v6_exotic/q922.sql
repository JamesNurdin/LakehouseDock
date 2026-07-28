WITH filtered_sales AS (
  SELECT
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    ca.ca_state,
    substring(ca.ca_city, 1, 3) AS city_prefix,
    ca.ca_zip,
    ca.ca_street_type,
    regexp_extract(ca.ca_zip, '(\\d{5})', 1) AS zip5
  FROM catalog_sales cs
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE ca.ca_zip LIKE '9%'                                   -- zip starts with 9
    AND (ca.ca_street_type LIKE '%Ave%' OR ca.ca_street_type LIKE '%Lane%')
    AND regexp_like(ca.ca_city, '^A')                         -- city name starts with "A"
)
SELECT
  fs.ca_state,
  fs.city_prefix,
  sum(fs.cs_net_profit) AS total_profit,
  sum(CASE WHEN fs.cs_net_profit > 1000 THEN fs.cs_net_profit ELSE 0 END) AS high_profit_total,
  avg(fs.cs_ext_discount_amt) AS avg_discount,
  (
    SELECT avg(cs_sub.cs_ext_discount_amt)
    FROM catalog_sales cs_sub
    JOIN customer_address ca_sub
      ON cs_sub.cs_bill_addr_sk = ca_sub.ca_address_sk
    WHERE ca_sub.ca_state = fs.ca_state
  ) AS state_avg_discount,
  min(fs.zip5) AS example_zip5
FROM filtered_sales fs
GROUP BY ROLLUP (fs.ca_state, fs.city_prefix)
ORDER BY fs.ca_state ASC NULLS LAST,
         fs.city_prefix ASC NULLS LAST
