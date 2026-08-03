WITH store_profit AS (
    SELECT
        p.p_promo_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(ss.ss_quantity) > 1000 THEN 'HIGH' ELSE 'LOW' END AS volume_category,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS rn
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(p.p_promo_name, '^.*Discount.*$')
      AND s.s_store_name LIKE '%Market%'
      AND substr(p.p_promo_id, 1, 3) = 'PROM'
    GROUP BY p.p_promo_id, s.s_store_name
),
web_profit AS (
    SELECT
        p.p_promo_id,
        'WEB' AS s_store_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws.ws_quantity) > 500 THEN 'HIGH' ELSE 'LOW' END AS volume_category,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(p.p_promo_name, '^.*Discount.*$')
      AND ws.ws_web_page_sk IS NOT NULL
      AND concat(p.p_promo_id, '_WEB') LIKE '%WEB%'
    GROUP BY p.p_promo_id
)
SELECT *
FROM (
    SELECT p_promo_id, s_store_name, total_net_profit, volume_category, rn
    FROM store_profit
    UNION
    SELECT p_promo_id, s_store_name, total_net_profit, volume_category, rn
    FROM web_profit
) AS combined
EXCEPT
SELECT p_promo_id, s_store_name, total_net_profit, volume_category, rn
FROM store_profit
WHERE volume_category = 'LOW'
ORDER BY total_net_profit DESC
LIMIT 100
