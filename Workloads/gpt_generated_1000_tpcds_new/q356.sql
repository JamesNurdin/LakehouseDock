WITH sales AS (
    SELECT
        ws.ws_order_number AS order_number,
        d.d_date AS trans_date,
        ws.ws_ext_sales_price AS amount,
        i.i_product_name AS product_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        w.w_warehouse_name AS location,
        'sale' AS trans_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 0
),
returns AS (
    SELECT
        wr.wr_order_number AS order_number,
        d.d_date AS trans_date,
        wr.wr_return_amt AS amount,
        i.i_product_name AS product_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'return' AS location,
        'return' AS trans_type
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 0
)
SELECT
    combined.order_number,
    combined.trans_date,
    combined.amount,
    combined.product_name,
    combined.customer_name,
    combined.location,
    combined.trans_type,
    ROW_NUMBER() OVER (ORDER BY combined.trans_date DESC, combined.amount DESC) AS rn
FROM (
    SELECT order_number, trans_date, amount, product_name, customer_name, location, trans_type FROM sales
    UNION
    SELECT order_number, trans_date, amount, product_name, customer_name, location, trans_type FROM returns
) AS combined
WHERE combined.order_number NOT IN (
    SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_quantity = 0
)
ORDER BY rn
LIMIT 100
