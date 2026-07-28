WITH promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year_code
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
)
SELECT
    pf.p_promo_name,
    pf.promo_year_code,
    sm.sm_type AS ship_mode,
    COUNT(ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    CONCAT('Promo_', COALESCE(pf.promo_year_code, 'NA')) AS promo_label
FROM promo_filtered pf
JOIN web_sales ws
  ON ws.ws_promo_sk = pf.p_promo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2002
  AND wp.wp_url LIKE '%example.com%'
  AND regexp_like(wp.wp_type, '^landing')
GROUP BY pf.p_promo_name,
         pf.promo_year_code,
         sm.sm_type,
         pf.p_promo_name,
         pf.promo_year_code
ORDER BY total_net_profit DESC
LIMIT 100
