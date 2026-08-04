WITH sales_enriched AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_quantity,
        cc.cc_name,
        cc.cc_class,
        cc.cc_company,
        cp.cp_type,
        sm.sm_type,
        d.d_year,
        CONCAT(cc.cc_name, '-', sm.sm_type) AS name_mode,
        SUBSTRING(cc.cc_name FROM 1 FOR 5) AS short_name,
        REGEXP_EXTRACT(cc.cc_name, '(A.*)', 1) AS extracted_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(cc.cc_name, '^A.*')
      AND cp.cp_type LIKE '%ELECT%'
      AND CONCAT(cc.cc_name, '-', sm.sm_type) LIKE '%-%'
      AND REGEXP_EXTRACT(cc.cc_name, '(A.*)', 1) != ''
)
SELECT
    short_name,
    cc_class,
    d_year,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_cnt
FROM sales_enriched
GROUP BY GROUPING SETS (
    (short_name, cc_class, d_year),
    (short_name, d_year),
    (d_year),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
