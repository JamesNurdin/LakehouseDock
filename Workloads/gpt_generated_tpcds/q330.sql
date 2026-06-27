WITH sales AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_web_page_sk AS page_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number,
        1 AS sales_flag,
        0 AS return_flag,
        CAST(0 AS decimal(7,2)) AS return_amt,
        CAST(0 AS decimal(7,2)) AS net_loss
    FROM web_sales ws
),
returns AS (
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        wr.wr_web_page_sk AS page_sk,
        CAST(0 AS decimal(7,2)) AS net_paid,
        CAST(0 AS decimal(7,2)) AS net_profit,
        wr.wr_order_number AS order_number,
        0 AS sales_flag,
        1 AS return_flag,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    wp.wp_type,
    SUM(combined.net_paid) AS total_net_paid,
    SUM(combined.net_profit) AS total_net_profit,
    SUM(combined.return_amt) AS total_return_amt,
    SUM(combined.net_loss) AS total_net_loss,
    SUM(combined.net_profit) - SUM(combined.net_loss) AS net_profit_after_returns,
    COUNT(DISTINCT CASE WHEN combined.sales_flag = 1 THEN combined.order_number END) AS sales_orders,
    COUNT(DISTINCT CASE WHEN combined.return_flag = 1 THEN combined.order_number END) AS return_orders
FROM combined
JOIN customer c
    ON combined.cust_sk = c.c_customer_sk
JOIN web_page wp
    ON combined.page_sk = wp.wp_web_page_sk
WHERE c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    wp.wp_type
ORDER BY net_profit_after_returns DESC
LIMIT 100
