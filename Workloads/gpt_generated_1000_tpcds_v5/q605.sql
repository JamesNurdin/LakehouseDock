WITH filtered_ws AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_quantity,
        ws.ws_order_number
    FROM web_sales ws
    WHERE regexp_like(CAST(ws.ws_order_number AS varchar), '^[1-9][0-9]{5}$')
      AND ws.ws_quantity > 0
)
SELECT
    p.p_promo_name,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    CASE
        WHEN SUM(ws.ws_net_paid_inc_tax) > 50000 THEN 'Very High'
        WHEN SUM(ws.ws_net_paid_inc_tax) > 20000 THEN 'High'
        ELSE 'Normal'
    END AS revenue_category,
    CONCAT('URL-', SUBSTRING(wp.wp_url, 1, 15)) AS url_prefix
FROM filtered_ws ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_url LIKE '%/products/%'
  AND regexp_extract(wp.wp_url, 'products/([^/]+)', 1) IS NOT NULL
GROUP BY
    p.p_promo_name,
    wp.wp_type,
    CONCAT('URL-', SUBSTRING(wp.wp_url, 1, 15))
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
