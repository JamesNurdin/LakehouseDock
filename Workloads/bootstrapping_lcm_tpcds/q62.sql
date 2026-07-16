SELECT
    sold.d_year * 100 + sold.d_month_seq AS sale_year_month,
    ship.d_year * 100 + ship.d_month_seq AS ship_year_month,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFITABLE'
        ELSE 'UNPROFITABLE'
    END AS profit_status
FROM web_sales ws
JOIN date_dim AS sold
    ON ws.ws_sold_date_sk = sold.d_date_sk
JOIN date_dim AS ship
    ON ws.ws_ship_date_sk = ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory inv
    ON inv.inv_date_sk = sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = sold.d_date_sk
GROUP BY
    sold.d_year * 100 + sold.d_month_seq,
    ship.d_year * 100 + ship.d_month_seq,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    s.s_store_id,
    s.s_state
HAVING
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
