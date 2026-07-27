WITH filtered_pages AS (
    SELECT
        cp_catalog_page_sk,
        cp_department,
        cp_description,
        regexp_extract(cp_description, '(\\w+)', 1) AS first_word,
        CASE
            WHEN regexp_like(cp_description, '(?i)legal') THEN 'Legal'
            WHEN cp_description LIKE '%girls%' THEN 'Girls'
            ELSE 'Other'
        END AS category
    FROM catalog_page
    WHERE regexp_like(cp_description, '(?i)legal')
       OR cp_description LIKE '%girls%'
)
SELECT
    fp.cp_department,
    fp.category,
    fp.first_word,
    CONCAT(fp.cp_department, ':', fp.first_word) AS dept_word_label,
    SUBSTRING(fp.cp_description, 1, 30) AS short_desc,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_category
FROM filtered_pages fp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
GROUP BY
    fp.cp_department,
    fp.category,
    fp.first_word,
    fp.cp_description
ORDER BY total_net_profit DESC
LIMIT 100
