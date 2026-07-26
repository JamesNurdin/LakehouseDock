WITH sales_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(wr.wr_return_amt, 0) AS return_amt,
        CASE WHEN wr.wr_return_amt > 5000 THEN 1 ELSE 0 END AS high_return_flag
    FROM customer c
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_order_number = ws.ws_order_number
), cumulative AS (
    SELECT
        sr.c_customer_sk,
        sr.c_customer_id,
        sr.c_first_name,
        sr.c_last_name,
        sr.ws_sold_date_sk,
        SUM(sr.net_profit) OVER (PARTITION BY sr.c_customer_sk ORDER BY sr.ws_sold_date_sk ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
        SUM(sr.return_amt) OVER (PARTITION BY sr.c_customer_sk ORDER BY sr.ws_sold_date_sk ROWS UNBOUNDED PRECEDING) AS cumulative_return,
        MAX(sr.high_return_flag) OVER (PARTITION BY sr.c_customer_sk) AS any_high_return
    FROM sales_returns sr
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cum.cumulative_profit,
    cum.cumulative_return,
    CASE WHEN cum.any_high_return = 1 THEN 'Yes' ELSE 'No' END AS high_return_occurred,
    RANK() OVER (ORDER BY cum.cumulative_profit DESC) AS profit_rank,
    CASE 
        WHEN cum.cumulative_profit > 50000 THEN 'VIP'
        WHEN cum.cumulative_profit > 20000 THEN 'Gold'
        ELSE 'Regular'
    END AS customer_segment
FROM cumulative cum
JOIN customer c
    ON c.c_customer_sk = cum.c_customer_sk
WHERE cum.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
