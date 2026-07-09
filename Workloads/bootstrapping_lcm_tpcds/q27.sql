SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    d_ship.d_year AS ship_year,
    sm.sm_type AS ship_mode_type,
    s.s_store_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2017
  AND sm.sm_type IN ('Air', 'Ground')
  AND s.s_state = 'CA'
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_year,
    sm.sm_type,
    s.s_store_name
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
