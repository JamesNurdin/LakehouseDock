SELECT
    d_sold.d_year AS sold_year,
    sm.sm_type AS ship_mode_type,
    cc.cc_division_name AS call_center_division,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    MIN(d_first_sales.d_date) AS first_sales_date
FROM
    web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust_bill
        ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_open
        ON ws.ws_sold_date_sk = d_open.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.ws_ship_date_sk = d_close.d_date_sk
        AND cc.cc_closed_date_sk = d_close.d_date_sk
    JOIN date_dim d_first_sales
        ON cust_bill.c_first_sales_date_sk = d_first_sales.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2000 AND 2002
    AND sm.sm_code = 'AIR'
GROUP BY
    d_sold.d_year,
    sm.sm_type,
    cc.cc_division_name
ORDER BY
    total_sales DESC
LIMIT 100
