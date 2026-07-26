SELECT
    ship_c.c_customer_id AS ship_customer_id,
    p.p_promo_name,
    t.t_shift,
    COUNT(*) AS sale_count,
    SUM(cs.cs_net_profit) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY ship_c.c_customer_id ORDER BY SUM(cs.cs_net_profit) ASC) AS profit_rank,
    CASE
        WHEN SUM(cs.cs_net_profit) > 30000 THEN 'VERY HIGH'
        WHEN SUM(cs.cs_net_profit) > 15000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
WHERE t.t_shift = 'Evening'
GROUP BY ship_c.c_customer_id, p.p_promo_name, t.t_shift
HAVING SUM(cs.cs_net_profit) BETWEEN 5000 AND 40000
ORDER BY total_profit DESC, ship_customer_id
LIMIT 15
