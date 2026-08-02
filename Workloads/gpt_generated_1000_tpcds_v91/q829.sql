/*
Goal: Calculate total sales, returns, and net profit per billing customer, broken down by the hour of sale and the hour of return. Keep only customers whose total net profit exceeds 1 000 and who have at least one web page with more than 3 000 characters. The query uses deep joins across all five TPC‑DS tables, re‑uses the TIME_DIM and CUSTOMER tables under multiple aliases, aggregates results with GROUP BY and HAVING, orders by profit, and demonstrates a window function (ROW_NUMBER) inside a CTE.
*/
WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_time_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cr.cr_returned_time_sk) AS rn_return
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
)
SELECT
    cust_bill.c_customer_id,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    td_sale.t_hour AS sale_hour,
    td_return.t_hour AS return_hour,
    SUM(sr.cs_ext_sales_price)      AS total_sales_price,
    SUM(sr.cr_return_amount)        AS total_return_amount,
    SUM(sr.cs_net_profit)           AS total_net_profit,
    COUNT(DISTINCT sr.cs_order_number) AS num_orders,
    MAX(sr.rn_return)               AS max_return_seq
FROM sales_returns sr
JOIN time_dim td_sale
    ON sr.cs_sold_time_sk = td_sale.t_time_sk                     -- catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
JOIN time_dim td_return
    ON sr.cr_returned_time_sk = td_return.t_time_sk               -- catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
JOIN customer cust_bill
    ON sr.cs_bill_customer_sk = cust_bill.c_customer_sk           -- catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
JOIN customer cust_ship
    ON sr.cs_ship_customer_sk = cust_ship.c_customer_sk           -- catalog_sales.cs_ship_customer_sk = customer.c_customer_sk
JOIN customer cust_refunded
    ON sr.cr_refunded_customer_sk = cust_refunded.c_customer_sk   -- catalog_returns.cr_refunded_customer_sk = customer.c_customer_sk
JOIN customer cust_returning
    ON sr.cr_returning_customer_sk = cust_returning.c_customer_sk -- catalog_returns.cr_returning_customer_sk = customer.c_customer_sk
JOIN web_page wp_bill
    ON wp_bill.wp_customer_sk = cust_bill.c_customer_sk           -- web_page.wp_customer_sk = customer.c_customer_sk
JOIN web_page wp_ship
    ON wp_ship.wp_customer_sk = cust_ship.c_customer_sk           -- web_page.wp_customer_sk = customer.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp_check
    WHERE wp_check.wp_customer_sk = cust_bill.c_customer_sk
      AND wp_check.wp_char_count > 3000
)
GROUP BY
    cust_bill.c_customer_id,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    td_sale.t_hour,
    td_return.t_hour
HAVING
    SUM(sr.cs_net_profit) > 1000
ORDER BY
    total_net_profit DESC
LIMIT 100
