SELECT
    ship_c.c_customer_id AS ship_customer_id,
    p.p_promo_name,
    t.t_hour,
    SUM(cs.cs_net_paid_inc_tax) AS total_paid,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    PERCENT_RANK() OVER (PARTITION BY ship_c.c_customer_id ORDER BY SUM(cs.cs_net_paid_inc_tax)) AS paid_percentile
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
GROUP BY ship_c.c_customer_id, p.p_promo_name, t.t_hour
HAVING SUM(cs.cs_net_paid_inc_tax) > 8000
ORDER BY total_paid DESC, ship_customer_id
LIMIT 30
