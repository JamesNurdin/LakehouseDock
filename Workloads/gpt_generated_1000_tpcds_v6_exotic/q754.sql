WITH catalog_web_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        SUM(wp.wp_char_count) AS total_chars
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_catalog_number BETWEEN 5 AND 20
      AND d.d_year = 1999
      AND d.d_fy_quarter_seq IN (2, 3, 6)
      AND wp.wp_type = 'home'
      AND wp.wp_char_count > 5000
    GROUP BY ROLLUP(cp.cp_department, cp.cp_type, d.d_year)
)
SELECT
    cp_department,
    cp_type,
    d_year,
    page_cnt,
    total_chars,
    CASE WHEN total_chars > 100000 THEN 'Large' ELSE 'Small' END AS size_category,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_chars DESC) AS dept_rank
FROM catalog_web_agg
WHERE cp_department IS NOT NULL OR cp_type IS NOT NULL
ORDER BY cp_department, dept_rank
LIMIT 100
