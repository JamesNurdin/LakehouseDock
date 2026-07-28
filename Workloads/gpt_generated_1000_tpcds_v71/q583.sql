WITH filtered_sales AS (
   SELECT
       ws.ws_web_site_sk,
       ws.ws_net_paid,
       ws.ws_quantity,
       wp.wp_url,
       wsite.web_site_id,
       wsite.web_name,
       wsite.web_manager,
       d.d_year
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE regexp_like(wp.wp_url, '/product/[0-9]+')
     AND wsite.web_name LIKE '%Market%'
     AND d.d_year = 2001
)
SELECT
    fs.web_site_id,
    fs.web_name,
    CONCAT(fs.web_name, ' - ', fs.web_manager) AS site_info,
    SUBSTRING(fs.web_manager FROM 1 FOR 5) AS manager_prefix,
    SUM(fs.ws_net_paid) AS total_net_paid,
    COUNT(*) AS sales_transactions,
    COUNT(DISTINCT CAST(regexp_extract(fs.wp_url, '/product/([0-9]+)', 1) AS integer)) AS distinct_product_ids,
    AVG(fs.ws_quantity) AS avg_quantity
FROM filtered_sales fs
GROUP BY
    fs.web_site_id,
    fs.web_name,
    fs.web_manager
ORDER BY total_net_paid DESC
LIMIT 100
