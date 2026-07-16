SELECT
    sm.sm_type,
    cd.cd_gender,
    c.c_customer_sk,
    c.c_email_address,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count,
    (SELECT MAX(ws2.ws_ext_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_sold_date_sk = CAST(2451705 AS integer)) AS max_sales_price
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_sold_date_sk = CAST(2451705 AS integer)
GROUP BY sm.sm_type, cd.cd_gender, c.c_customer_sk, c.c_email_address
HAVING SUM(ws.ws_ext_sales_price) > 571.13
