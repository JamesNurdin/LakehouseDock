WITH sales_summary AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount')
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY cp.cp_catalog_page_id, p.p_promo_name
)
SELECT
    cp_id,
    promo_name,
    total_net_paid,
    sales_cnt,
    substring(cp_id, 1, 5) AS cp_prefix,
    regexp_extract(promo_name, '(Summer|Winter)', 1) AS season,
    concat(cp_id, '-', promo_name) AS combined_key
FROM sales_summary
ORDER BY total_net_paid DESC
LIMIT 100
