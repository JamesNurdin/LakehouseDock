WITH sales_page AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        wp.wp_url,
        wp.wp_type
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
filtered_sales AS (
    SELECT
        sp.ws_ext_sales_price,
        sp.ws_item_sk,
        sp.ws_sold_date_sk,
        regexp_extract(sp.wp_url, 'https?://([^/]+)', 1) AS domain
    FROM sales_page sp
    JOIN tpcds.date_dim d
        ON sp.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND sp.wp_type LIKE 'ad%'
      AND regexp_like(sp.wp_url, '^https?://')
)
SELECT
    domain,
    COUNT(*) AS visit_count,
    SUM(ws_ext_sales_price) AS total_sales
FROM filtered_sales
GROUP BY domain
ORDER BY total_sales DESC
LIMIT 20
