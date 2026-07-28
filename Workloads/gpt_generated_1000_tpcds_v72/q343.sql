WITH page_desc AS (
    SELECT
        cp.cp_catalog_page_sk,
        regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
        lower(cp.cp_description) AS description_lower
    FROM catalog_page cp
    WHERE cp.cp_description IS NOT NULL
)
SELECT
    concat(cc.cc_name, ': ', pd.first_word) AS name_category,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
FROM catalog_sales cs
JOIN page_desc pd ON cs.cs_catalog_page_sk = pd.cp_catalog_page_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND regexp_like(pd.description_lower, '^.*sale.*$')
  AND cc.cc_name LIKE 'A%'
  AND substr(cc.cc_name, 1, 1) = 'A'
GROUP BY concat(cc.cc_name, ': ', pd.first_word)
ORDER BY total_net_profit DESC
LIMIT 100
