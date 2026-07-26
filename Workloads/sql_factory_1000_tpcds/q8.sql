WITH cust_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount
    FROM customer c
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_order_number = ws.ws_order_number
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.total_net_profit,
    c.total_return_amount,
    CASE WHEN c.total_net_profit > 0 THEN c.total_return_amount / c.total_net_profit ELSE NULL END AS return_ratio,
    CASE
        WHEN c.total_net_profit > 20000 THEN 'High'
        WHEN c.total_net_profit BETWEEN 5000 AND 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY c.total_net_profit DESC) AS profit_rank
FROM cust_agg c
