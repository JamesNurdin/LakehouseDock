WITH sales_filtered AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        cs.cs_ext_sales_price,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        td.t_shift,
        td.t_sub_shift,
        cp.cp_description
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)promo')
      AND cc.cc_name LIKE '%Center%'
      AND td.t_sub_shift = 'morning'
)
SELECT
    cc_name,
    concat(cc_city, ', ', cc_state) AS location,
    t_shift,
    COUNT(DISTINCT cs_call_center_sk) AS distinct_call_centers,
    SUM(cs_ext_sales_price) AS total_sales,
    regexp_extract(cc_name, '(\\w+) Center', 1) AS name_prefix
FROM sales_filtered
GROUP BY
    cc_name,
    concat(cc_city, ', ', cc_state),
    t_shift,
    regexp_extract(cc_name, '(\\w+) Center', 1)
HAVING SUM(cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 10
