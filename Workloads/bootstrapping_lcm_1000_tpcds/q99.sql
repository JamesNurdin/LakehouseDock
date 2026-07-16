SELECT
    s.s_store_name,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_promo_start.d_year = 2022
GROUP BY s.s_store_name, d_sold.d_year, d_ship.d_month_seq, p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
