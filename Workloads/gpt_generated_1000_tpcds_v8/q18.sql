-- Goal: Identify sales and return amounts per order, combine them, and then retain all orders and all customers (including those without matching orders) while adding a row number for further downstream processing.
WITH sales_part AS (
    SELECT
        ws.ws_order_number       AS order_number,
        ws.ws_bill_customer_sk   AS customer_sk,
        ws.ws_web_page_sk        AS page_sk,
        ws.ws_ext_sales_price    AS amount,
        wp.wp_type               AS page_type,
        wp.wp_autogen_flag       AS page_autogen_flag
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'ad'
      AND wp.wp_autogen_flag = 'N'
),
returns_part AS (
    SELECT
        wr.wr_order_number       AS order_number,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_web_page_sk        AS page_sk,
        (wr.wr_refunded_cash * -1) AS amount,
        wp.wp_type               AS page_type,
        wp.wp_autogen_flag       AS page_autogen_flag
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_refunded_cash > 200
),
unioned AS (
    SELECT order_number, customer_sk, page_sk, amount, page_type, page_autogen_flag
    FROM sales_part
    UNION ALL
    SELECT order_number, customer_sk, page_sk, amount, page_type, page_autogen_flag
    FROM returns_part
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(u.order_number, 0)) AS row_num,
    u.order_number,
    u.customer_sk,
    u.page_sk,
    u.amount,
    c.c_first_name,
    c.c_last_name
FROM unioned u
FULL OUTER JOIN tpcds.customer c
      ON u.customer_sk = c.c_customer_sk
ORDER BY row_num
LIMIT 100
