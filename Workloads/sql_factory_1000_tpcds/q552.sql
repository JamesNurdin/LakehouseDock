WITH promo_shift_profit AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        t.t_shift,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY p.p_promo_id, p.p_promo_name, t.t_shift
)
SELECT
    p_promo_id,
    p_promo_name,
    t_shift,
    total_profit,
    sales_cnt,
    CASE
        WHEN total_profit > 100000 THEN 'HIGH'
        WHEN total_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM promo_shift_profit
ORDER BY profit_rank
LIMIT 10
