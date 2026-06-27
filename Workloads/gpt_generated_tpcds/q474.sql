WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        date_format(dd.d_date, '%Y-%m') AS year_month,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        COUNT(DISTINCT ss.ss_customer_sk) AS num_customers
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY
        ss.ss_store_sk,
        date_format(dd.d_date, '%Y-%m')
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        date_format(dd.d_date, '%Y-%m') AS year_month,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    WHERE dd.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY
        sr.sr_store_sk,
        date_format(dd.d_date, '%Y-%m')
)
SELECT
    s.s_store_name,
    sa.year_month,
    sa.total_sales,
    coalesce(ra.total_return_amount, 0) AS total_return_amount,
    (sa.total_sales - coalesce(ra.total_return_amount, 0)) AS net_sales_after_returns,
    sa.total_profit,
    coalesce(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_profit - coalesce(ra.total_return_loss, 0)) AS net_profit_after_returns,
    sa.num_transactions,
    coalesce(ra.num_return_transactions, 0) AS num_return_transactions,
    (coalesce(ra.total_return_amount, 0) / nullif(sa.total_sales, 0)) * 100 AS return_rate_percent
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
    AND sa.year_month = ra.year_month
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
ORDER BY
    s.s_store_name,
    sa.year_month
