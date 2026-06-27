WITH sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
),
returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store_returns sr
)
SELECT
    st.s_store_name,
    d.d_year,
    d.d_moy AS month,
    SUM(sales.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(returns.sr_net_loss, 0)) AS total_return_loss,
    SUM(sales.ss_net_profit) - SUM(COALESCE(returns.sr_net_loss, 0)) AS net_profit_after_returns
FROM sales
LEFT JOIN returns
    ON sales.ss_ticket_number = returns.sr_ticket_number
JOIN store st
    ON sales.ss_store_sk = st.s_store_sk
JOIN date_dim d
    ON sales.ss_sold_date_sk = d.d_date_sk
WHERE d.d_date >= DATE '1998-01-01'
  AND d.d_date < DATE '2001-01-01'
GROUP BY st.s_store_name, d.d_year, d.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 10
