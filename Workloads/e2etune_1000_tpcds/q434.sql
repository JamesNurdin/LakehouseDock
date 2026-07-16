WITH store_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        t.t_hour,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        AVG(ss.ss_ext_discount_amt) AS store_avg_discount
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY p.p_promo_sk, p.p_promo_name, t.t_hour
),
web_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        t.t_hour,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        AVG(ws.ws_ext_discount_amt) AS web_avg_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY p.p_promo_sk, p.p_promo_name, t.t_hour
)
SELECT
    COALESCE(sa.p_promo_sk, wa.p_promo_sk) AS promo_sk,
    COALESCE(sa.p_promo_name, wa.p_promo_name) AS promo_name,
    COALESCE(sa.t_hour, wa.t_hour) AS hour_of_day,
    COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    (COALESCE(sa.store_avg_discount, 0) * COALESCE(sa.store_quantity, 0) +
     COALESCE(wa.web_avg_discount, 0) * COALESCE(wa.web_quantity, 0))
        / NULLIF(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0), 0) AS weighted_avg_discount,
    RANK() OVER (ORDER BY (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) DESC) AS profit_rank
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.p_promo_sk = wa.p_promo_sk
   AND sa.t_hour = wa.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
