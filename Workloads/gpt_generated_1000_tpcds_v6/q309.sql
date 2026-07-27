WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_catalog_number,
        regexp_extract(cp_description, '(\\w+)', 1) AS first_word,
        cp_description
    FROM catalog_page
    WHERE cp_description LIKE '%sale%'
      AND regexp_like(cp_description, '^.*[0-9]{4}.*$')
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    filtered_pages.first_word,
    sum(cs.cs_net_profit) AS total_net_profit,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    max(d.d_year) AS latest_year
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN filtered_pages
  ON cs.cs_catalog_page_sk = filtered_pages.cp_catalog_page_sk
WHERE cc.cc_hours LIKE '8AM-%'
  AND regexp_like(cc.cc_street_type, '^(Boulevard|Rd|Way)$')
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    filtered_pages.first_word,
    cc.cc_hours
HAVING sum(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
