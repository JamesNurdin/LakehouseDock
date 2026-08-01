WITH ws AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid,
           ws.ws_web_page_sk,
           ws.ws_promo_sk,
           ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '^.*Discount.*$')
      AND ws.ws_net_paid > 0
),
wp AS (
    SELECT wp.wp_web_page_sk,
           regexp_extract(wp.wp_url, '://([^/]+)', 1) AS domain
    FROM web_page wp
    WHERE wp.wp_url LIKE 'http://%example.com%'
),
ws_joined AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid,
           wp.domain,
           p.p_promo_name,
           ws.ws_bill_customer_sk
    FROM ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT c.c_customer_id,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
       ws_agg.total_ws_net_paid,
       ss_agg.total_ss_net_paid,
       ws_agg.domain
FROM (
    SELECT ws_joined.ws_bill_customer_sk AS customer_sk,
           ws_joined.domain,
           SUM(ws_joined.ws_net_paid) AS total_ws_net_paid
    FROM ws_joined
    GROUP BY ws_joined.ws_bill_customer_sk, ws_joined.domain
) ws_agg
JOIN (
    SELECT ss.ss_customer_sk AS customer_sk,
           SUM(ss.ss_net_paid) AS total_ss_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_city LIKE 'San %'
    GROUP BY ss.ss_customer_sk
) ss_agg
    ON ws_agg.customer_sk = ss_agg.customer_sk
JOIN customer c ON c.c_customer_sk = ws_agg.customer_sk
ORDER BY ws_agg.total_ws_net_paid DESC
LIMIT 100
