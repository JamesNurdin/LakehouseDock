WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '(?i)clearance')
      AND ws.ws_web_page_sk IS NOT NULL
)
SELECT
    d.d_year,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    p.p_channel_email,
    COUNT(DISTINCT f.ws_order_number) AS orders,
    SUM(f.ws_net_profit) AS total_profit,
    CONCAT(p.p_promo_name, ' - ', wp.wp_type) AS promo_page_type
FROM filtered_sales f
JOIN date_dim d ON f.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON f.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON f.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit ON f.ws_web_site_sk = wsit.web_site_sk
WHERE wp.wp_url LIKE '%example.com%'
  AND wsit.web_name LIKE '%Shop%'
GROUP BY
    d.d_year,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
    p.p_channel_email,
    CONCAT(p.p_promo_name, ' - ', wp.wp_type)
ORDER BY total_profit DESC
LIMIT 100
