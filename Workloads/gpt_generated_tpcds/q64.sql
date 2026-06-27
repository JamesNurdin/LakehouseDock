WITH sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_year
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(sales.ss_quantity) AS total_quantity_sold,
    SUM(sales.ss_net_profit) AS total_sales_net_profit,
    SUM(COALESCE(returns.sr_return_quantity, 0)) AS total_quantity_returned,
    SUM(COALESCE(returns.sr_net_loss, 0)) AS total_return_net_loss,
    SUM(sales.ss_net_profit) - SUM(COALESCE(returns.sr_net_loss, 0)) AS net_profit_after_returns
FROM sales
LEFT JOIN returns
    ON sales.ss_ticket_number = returns.sr_ticket_number
JOIN store s
    ON sales.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_name, s.s_city, s.s_state
ORDER BY net_profit_after_returns DESC
LIMIT 10
