WITH filtered_pages AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        regexp_extract(wp_url, '^https?://([^/]+)/', 1) AS domain,
        CASE
            WHEN wp_url LIKE '%promo%' THEN 'PromoURL'
            ELSE 'OtherURL'
        END AS url_category
    FROM web_page
    WHERE regexp_like(wp_url, '^https?://')
)
SELECT
    fp.domain,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    CONCAT(fp.domain, '_', COALESCE(p.p_promo_id, 'NO_PROMO')) AS domain_promo_key
FROM filtered_pages fp
JOIN web_sales ws ON ws.ws_web_page_sk = fp.wp_web_page_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE fp.url_category = 'PromoURL'
  AND p.p_channel_email = 'Y'
GROUP BY
    fp.domain,
    p.p_promo_name,
    p.p_promo_id
ORDER BY total_net_paid DESC
LIMIT 20
