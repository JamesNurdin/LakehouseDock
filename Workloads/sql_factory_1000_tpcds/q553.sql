SELECT
    ship_c.c_customer_id AS ship_customer_id,
    p.p_promo_name,
    t.t_shift,
    SUM(cs.cs_net_profit) AS total_profit,
    RANK() OVER (PARTITION BY ship_c.c_customer_id ORDER BY SUM(cs.cs_net_profit) DESC) AS promo_rank,
    CASE
        WHEN SUM(cs.cs_net_profit) > 20000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM catalog_sales cs
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer ship_c
    ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
GROUP BY ship_c.c_customer_id, p.p_promo_name, t.t_shift
HAVING SUM(cs.cs_net_profit) > 5000
ORDER BY ship_customer_id, promo_rank
LIMIT 20
