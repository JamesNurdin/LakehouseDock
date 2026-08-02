WITH promo_sales AS (
    SELECT
        'Promotion' AS key_type,
        COALESCE(p.p_promo_name, 'No Promotion') AS key_desc,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount,
        CASE
            WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) >= 50000 THEN 'High'
            WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) >= 20000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_volume_category
    FROM promotion p
    FULL OUTER JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY COALESCE(p.p_promo_name, 'No Promotion')
),
webpage_sales AS (
    SELECT
        'Web Page' AS key_type,
        CONCAT('Domain: ', COALESCE(REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)'), 'Unknown')) AS key_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        CASE
            WHEN SUM(ws.ws_ext_sales_price) >= 50000 THEN 'High'
            WHEN SUM(ws.ws_ext_sales_price) >= 20000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_volume_category
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE 'http%://%example.com/%'
    GROUP BY CONCAT('Domain: ', COALESCE(REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)'), 'Unknown'))
)
SELECT
    key_type,
    key_desc,
    total_sales,
    total_discount,
    sales_volume_category
FROM promo_sales
UNION ALL
SELECT
    key_type,
    key_desc,
    total_sales,
    total_discount,
    sales_volume_category
FROM webpage_sales
ORDER BY total_sales DESC
LIMIT 100
