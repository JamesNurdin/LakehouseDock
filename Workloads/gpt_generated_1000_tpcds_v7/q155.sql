WITH page_sales AS (
    SELECT
        wp.wp_type,
        wp.wp_url,
        REGEXP_EXTRACT(wp.wp_url, '://([^/]+)') AS domain,
        d.d_day_name,
        cs.cs_ext_sales_price,
        cs.cs_ext_tax
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com')
      AND wp.wp_type LIKE 'C%'
)
SELECT
    wp_type,
    domain,
    COUNT(*) AS page_views,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_sales_price) AS avg_sales,
    SUM(cs_ext_tax) AS total_tax,
    CONCAT('Type_', wp_type) AS type_label
FROM page_sales
GROUP BY wp_type, domain
HAVING COUNT(*) > 5
ORDER BY total_sales DESC
LIMIT 10
