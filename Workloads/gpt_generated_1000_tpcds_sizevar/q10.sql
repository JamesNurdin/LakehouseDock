SELECT
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name,
    SUM(web_sales.ws_net_paid_inc_ship) AS total_paid,
    AVG(web_sales.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS order_count
FROM web_sales
JOIN customer
    ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
WHERE customer.c_first_shipto_date_sk = 2451506
  AND web_sales.ws_quantity > 50
GROUP BY
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name
