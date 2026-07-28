WITH ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'lunch'
      AND regexp_like(td.t_time_id, '^AAAAAAA[AP]')
),
promo AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_pct,
        p.p_promo_id
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)discount|sale')
),
wp AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        substring(wp.wp_url, 1, 10) AS url_prefix
    FROM web_page wp
    WHERE wp.wp_url LIKE '%/promo/%'
)
SELECT
    promo.p_promo_name,
    promo.discount_pct,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(ws.ws_order_number) AS orders,
    MIN(wp.url_prefix) AS sample_url_prefix
FROM ws
JOIN promo ON ws.ws_promo_sk = promo.p_promo_sk
JOIN wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
GROUP BY promo.p_promo_name, promo.discount_pct
ORDER BY total_net_paid DESC
LIMIT 10
