WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        p.p_purpose,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '^.*Holiday.*$')
      AND p.p_channel_details LIKE '%email%'
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_details, p.p_purpose
)
SELECT
    ps.p_promo_sk,
    ps.p_promo_name,
    regexp_extract(ps.p_promo_name, '(Holiday[0-9]{2})', 1) AS promo_code,
    ps.p_channel_details,
    ps.total_net_profit,
    ps.order_cnt,
    ps.avg_discount,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_profit
FROM promo_sales ps
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_purpose = ps.p_purpose
      AND p2.p_promo_sk <> ps.p_promo_sk
      AND p2.p_discount_active = 'Y'
)
ORDER BY ps.total_net_profit DESC
LIMIT 100
