SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS month_seq,
    hd_bill.hd_buy_potential AS buy_potential,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
    AND sr.sr_returned_date_sk = d_sold.d_date_sk
    AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c_bill.c_customer_sk
    AND wr.wr_returned_date_sk = d_sold.d_date_sk
    AND wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
WHERE
    d_sold.d_year = 2001
    AND d_sold.d_month_seq BETWEEN 1200 AND 1203
    AND c_bill.c_preferred_cust_flag = 'Y'
    AND hd_bill.hd_buy_potential = 'HIGH'
    AND ws.ws_quantity >= 2
    AND sr.sr_return_quantity > 5
    AND ws.ws_ext_sales_price > (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = d_sold.d_date_sk
    )
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    hd_bill.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
