WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_web_page_sk AS page_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2449000 AND 2451000
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_refunded_customer_sk AS cust_sk,
        wr.wr_web_page_sk AS page_sk,
        wr.wr_net_loss,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2449000 AND 2451000
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    wp.wp_type,
    SUM(sa.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(ra.wr_net_loss), 0) AS total_return_loss,
    SUM(sa.ws_net_profit) - COALESCE(SUM(ra.wr_net_loss), 0) AS net_profit_after_returns,
    AVG(sa.ws_ext_discount_amt) AS avg_discount,
    SUM(sa.ws_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY SUM(sa.ws_net_profit) - COALESCE(SUM(ra.wr_net_loss), 0) DESC) AS profit_rank
FROM sales_agg sa
JOIN customer c
    ON c.c_customer_sk = sa.cust_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = sa.page_sk
LEFT JOIN returns_agg ra
    ON ra.wr_order_number = sa.ws_order_number
    AND ra.cust_sk = sa.cust_sk
    AND ra.page_sk = sa.page_sk
WHERE c.c_birth_year >= 1960
GROUP BY c.c_customer_id, c.c_birth_year, wp.wp_type
HAVING SUM(sa.ws_net_profit) - COALESCE(SUM(ra.wr_net_loss), 0) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 20
