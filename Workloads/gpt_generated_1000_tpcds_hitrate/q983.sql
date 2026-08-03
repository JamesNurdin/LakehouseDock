WITH call_center_sales AS (
  SELECT
    cs.cs_call_center_sk,
    SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cs.cs_call_center_sk
),
call_center_pages AS (
  SELECT
    cs.cs_call_center_sk,
    ARRAY_AGG(DISTINCT cp.cp_type) AS page_types
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  GROUP BY cs.cs_call_center_sk
)
SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  regexp_extract(cc.cc_name, '^([^ ]+)') AS first_word,
  substring(cc.cc_county FROM 1 FOR 3) AS county_prefix,
  cs.total_profit,
  CASE
    WHEN cs.total_profit > (SELECT AVG(total_profit) FROM call_center_sales) THEN 'Above Avg'
    WHEN cs.total_profit > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category,
  cp.page_types
FROM call_center_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN call_center_pages cp ON cs.cs_call_center_sk = cp.cs_call_center_sk
WHERE
  cc.cc_name LIKE 'A%'
  AND regexp_like(cc.cc_city, '^New')
  AND cc.cc_country = 'United States'
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  regexp_extract(cc.cc_name, '^([^ ]+)'),
  substring(cc.cc_county FROM 1 FOR 3),
  cs.total_profit,
  cp.page_types
ORDER BY cs.total_profit DESC
LIMIT 50
