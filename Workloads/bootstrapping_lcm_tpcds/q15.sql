SELECT
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
    SUM(ws.ws_net_profit) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS profit_per_inventory,
    SUM(CASE WHEN d_sold.d_holiday = 'Y' THEN ws.ws_ext_discount_amt ELSE 0 END) AS holiday_discount_total,
    COUNT(*) FILTER (WHERE ws.ws_quantity > 5) AS high_quantity_sales
FROM
    web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_date_sk = d_sold.d_date_sk
    AND i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2012 AND 2015
    AND w.w_state = 'CA'
GROUP BY
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING
    SUM(ws.ws_net_profit) > 0
ORDER BY
    profit_per_inventory DESC
LIMIT 100
