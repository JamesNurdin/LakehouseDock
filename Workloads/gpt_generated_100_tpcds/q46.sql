WITH sales_2020 AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
returns_2020 AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT s.ws_order_number) AS orders,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.ws_ext_discount_amt) AS avg_discount,
    COALESCE(SUM(r.wr_return_quantity), 0) AS total_return_quantity,
    COUNT(DISTINCT wp.wp_url) AS distinct_web_pages,
    MAX(d_sold.d_date) AS last_purchase_date
FROM sales_2020 s
JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN returns_2020 r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold ON s.ws_sold_date_sk = d_sold.d_date_sk
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_profit DESC
LIMIT 10
