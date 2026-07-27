WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        CASE
            WHEN wr.wr_return_quantity IS NULL THEN ws.ws_net_profit
            ELSE ws.ws_net_profit - wr.wr_return_amt
        END AS adj_net_profit
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    c.c_customer_id,
    d_sold.d_year,
    COUNT(DISTINCT sr.ws_order_number) AS distinct_orders,
    SUM(sr.ws_quantity) AS total_quantity,
    SUM(sr.ws_net_profit) AS total_net_profit,
    SUM(sr.adj_net_profit) AS total_adj_net_profit,
    AVG(sr.ws_net_profit) AS avg_net_profit,
    MIN(sr.ws_net_profit) AS min_net_profit,
    MAX(sr.ws_net_profit) AS max_net_profit
FROM sales_returns sr
JOIN date_dim d_sold
    ON sr.ws_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON sr.ws_bill_customer_sk = c.c_customer_sk
WHERE d_sold.d_year = 2001
  AND c.c_birth_month = 7
  AND sr.ws_quantity > 2
GROUP BY c.c_customer_id, d_sold.d_year
ORDER BY total_adj_net_profit DESC
LIMIT 100
