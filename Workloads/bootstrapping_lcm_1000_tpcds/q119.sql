SELECT
    c_bill.c_birth_month,
    CASE 
        WHEN c_bill.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c_bill.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c_bill.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS birth_quarter,
    c_bill.c_birth_year,
    (c_bill.c_birth_year - d_c_first_sales.d_year) AS years_since_first_sale,
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    d_c_first_sales.d_year AS first_sales_year,
    d_c_first_ship.d_year AS first_ship_year,
    COUNT(*) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(CASE WHEN ws.ws_coupon_amt > 0 THEN 1 ELSE 0 END) AS coupon_orders,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'profitable' ELSE 'unprofitable' END AS profit_indicator,
    (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS net_price_ratio,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) * 100 AS profit_percent
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c_page
    ON wp.wp_customer_sk = c_page.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_c_first_sales
    ON c_bill.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN date_dim d_c_first_ship
    ON c_bill.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
WHERE d_sold.d_year = 2000
  AND s.s_state IS NOT NULL
GROUP BY
    c_bill.c_birth_month,
    CASE 
        WHEN c_bill.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c_bill.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c_bill.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    c_bill.c_birth_year,
    (c_bill.c_birth_year - d_c_first_sales.d_year),
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    d_c_first_sales.d_year,
    d_c_first_ship.d_year
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
