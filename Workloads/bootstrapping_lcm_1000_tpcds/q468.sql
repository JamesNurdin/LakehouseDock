SELECT
    d.d_year AS sold_year,
    d.d_quarter_name AS sold_quarter,
    d_ship.d_month_seq AS ship_month,
    d_create.d_month_seq AS page_creation_month,
    d_access.d_dow AS page_access_weekday,
    hd_bill.hd_buy_potential AS bill_buy_potential,
    hd_ship.hd_buy_potential AS ship_buy_potential,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space > 20000 THEN 'Medium Store'
        ELSE 'Small Store'
    END AS store_size,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN wp.wp_type = 'product' THEN ws.ws_ext_sales_price ELSE 0 END) AS product_sales,
    SUM(CASE WHEN wp.wp_type = 'advertisement' THEN ws.ws_ext_sales_price ELSE 0 END) AS ad_sales
FROM date_dim d
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year >= 2020
  AND s.s_state IN ('CA', 'TX')
GROUP BY
    d.d_year,
    d.d_quarter_name,
    d_ship.d_month_seq,
    d_create.d_month_seq,
    d_access.d_dow,
    hd_bill.hd_buy_potential,
    hd_ship.hd_buy_potential,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space > 20000 THEN 'Medium Store'
        ELSE 'Small Store'
    END
HAVING SUM(ws.ws_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
