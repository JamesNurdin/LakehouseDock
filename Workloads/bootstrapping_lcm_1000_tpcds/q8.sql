SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_quarter_name AS sale_quarter,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_quantity ELSE 0 END) AS weekend_quantity,
    SUM(CASE WHEN d_ship.d_dow IN (6,7) THEN ws.ws_quantity ELSE 0 END) AS weekend_quantity_by_dow,
    CASE WHEN d_inv.d_year = d_sold.d_year THEN 'SameYear' ELSE 'DiffYear' END AS inventory_year_relation
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    d_inv.d_year,
    CASE WHEN d_inv.d_year = d_sold.d_year THEN 'SameYear' ELSE 'DiffYear' END
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
