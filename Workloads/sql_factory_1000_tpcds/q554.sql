SELECT
    bill_c.c_customer_id AS bill_customer_id,
    ship_c.c_customer_id AS ship_customer_id,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    DENSE_RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(cs.cs_net_profit) > 50000 THEN 'Platinum'
        WHEN SUM(cs.cs_net_profit) > 20000 THEN 'Gold'
        WHEN SUM(cs.cs_net_profit) > 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    t.t_meal_time
FROM catalog_sales cs
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer bill_c
    ON cs.cs_bill_customer_sk = bill_c.c_customer_sk
JOIN customer ship_c
    ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
WHERE p.p_discount_active = 'Y'
GROUP BY bill_c.c_customer_id, ship_c.c_customer_id, t.t_meal_time
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 15
