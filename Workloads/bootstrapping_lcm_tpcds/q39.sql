SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_moy AS sold_month,
    d_ship.d_quarter_name AS ship_quarter,
    s.s_state AS store_state,
    hd_bill.hd_buy_potential AS buyer_potential,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(hd_ship.hd_vehicle_count) AS avg_ship_vehicle_count,
    SUM(CASE WHEN d_sold.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_sales_count,
    SUM(ws.ws_net_profit) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) AS profit_per_order
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE ws.ws_net_profit > 0
GROUP BY
    d_sold.d_year,
    d_sold.d_moy,
    d_ship.d_quarter_name,
    s.s_state,
    hd_bill.hd_buy_potential
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
