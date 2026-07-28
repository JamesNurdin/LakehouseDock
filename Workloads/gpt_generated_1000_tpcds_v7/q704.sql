WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_description,
        cp.cp_department,
        cp.cp_type,
        regexp_extract(cp.cp_description, '(\\d+)', 1) AS desc_num,
        (cp.cp_department || '_' || cp.cp_type) AS dept_type
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '[A-Z]{2}[0-9]{2}')
      AND cp.cp_type LIKE '%Annual%'
      AND regexp_like((cp.cp_department || '_' || cp.cp_type), '^Home_.*')
)
SELECT
    dd.d_year,
    fp.cp_catalog_page_id,
    fp.cp_description,
    fp.desc_num,
    COUNT(*) AS sales_count,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit
FROM filtered_pages fp
JOIN catalog_sales cs
      ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
JOIN date_dim dd
      ON cs.cs_sold_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 1999 AND 2001
GROUP BY
    dd.d_year,
    fp.cp_catalog_page_id,
    fp.cp_description,
    fp.desc_num
ORDER BY total_net_profit DESC
LIMIT 20
