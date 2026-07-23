SELECT
    s.s_store_id,
    s.s_store_name,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_bill.cd_credit_rating,
    wp.wp_type,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    MIN(ws.ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(ws.ws_ext_wholesale_cost) AS max_wholesale_cost,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE
    cd_bill.cd_gender = 'M'
    AND cd_bill.cd_marital_status = 'M'
    AND cd_bill.cd_credit_rating = 'A'
    AND s.s_market_id IN (3, 4, 7, 8)
    AND s.s_floor_space > 8000000
    AND wp.wp_type = 'Content'
    AND ws.ws_ext_wholesale_cost > 1000
    AND ws.ws_quantity BETWEEN 2 AND 5
    AND sr.sr_return_amt_inc_tax > 500
    AND ws.ws_sold_date_sk BETWEEN 2451540 AND 2451550
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_bill.cd_credit_rating,
    wp.wp_type
HAVING
    SUM(ws.ws_net_paid) > 100000
    AND SUM(sr.sr_return_amt_inc_tax) > 1000
ORDER BY
    total_net_paid DESC
LIMIT 100
