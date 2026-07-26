SELECT
    ship_c.c_customer_id AS ship_customer_id,
    p.p_promo_name,
    t.t_meal_time,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY t.t_meal_time ORDER BY AVG(cs.cs_net_profit) DESC) AS meal_profit_rank
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
WHERE cs.cs_quantity > 1
GROUP BY ship_c.c_customer_id, p.p_promo_name, t.t_meal_time
HAVING AVG(cs.cs_net_profit) > 1000
ORDER BY meal_profit_rank, ship_customer_id
LIMIT 10
