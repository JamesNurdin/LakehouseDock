WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        s.s_city,
        s.s_state,
        s.s_hours,
        p.p_promo_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_hours LIKE '8AM-%'
      AND regexp_like(p.p_promo_name, '^Promo[0-9]{3}')
      AND t.t_hour BETWEEN 8 AND 12
)
SELECT
    concat(s_city, ', ', s_state) AS store_location,
    regexp_extract(p_promo_name, '(\\d{3})', 1) AS promo_code,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_net_profit) AS total_net_profit
FROM filtered_sales
GROUP BY concat(s_city, ', ', s_state), regexp_extract(p_promo_name, '(\\d{3})', 1)
ORDER BY total_net_profit DESC
LIMIT 100
