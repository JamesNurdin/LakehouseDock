WITH filtered_web AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_link_count,
        wp.wp_customer_sk,
        d_wp.d_year AS wp_creation_year,
        regexp_extract(wp.wp_url, '^https?://([^/]+)\\.com', 1) AS domain
    FROM web_page wp
    JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*\\.com')
      AND wp.wp_url LIKE '%example%'
)
SELECT
    cp.cp_department,
    d_start.d_year AS catalog_year,
    COUNT(DISTINCT fw.wp_web_page_sk) AS web_page_count,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customer_count,
    AVG(fw.wp_link_count) AS avg_link_count,
    CONCAT(cp.cp_department, '_', CAST(d_start.d_year AS VARCHAR)) AS dept_year_key
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN filtered_web fw ON 1 = 1  -- logical join, will be filtered by year below
JOIN customer c ON fw.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d_start.d_year = fw.wp_creation_year
  AND cd.cd_dep_college_count >= 2
GROUP BY
    cp.cp_department,
    d_start.d_year,
    CONCAT(cp.cp_department, '_', CAST(d_start.d_year AS VARCHAR))
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY web_page_count DESC
LIMIT 100
