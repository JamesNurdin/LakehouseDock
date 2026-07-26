WITH cs_time AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_net_profit,
        t.t_hour
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
),
promo_cum AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        cs.t_hour,
        SUM(cs.cs_net_profit) OVER (PARTITION BY p.p_promo_id ORDER BY cs.t_hour ROWS UNBOUNDED PRECEDING) AS cum_profit
    FROM cs_time cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
)
SELECT
    p_promo_id,
    p_promo_name,
    t_hour,
    cum_profit,
    RANK() OVER (PARTITION BY t_hour ORDER BY cum_profit DESC) AS rank_in_hour,
    CASE
        WHEN cum_profit > 0 THEN 'PROFIT'
        WHEN cum_profit < 0 THEN 'LOSS'
        ELSE 'ZERO'
    END AS profit_status
FROM promo_cum
ORDER BY t_hour, rank_in_hour
