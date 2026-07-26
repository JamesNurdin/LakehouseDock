WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions
    FROM store_sales
    WHERE ss_sales_price > 0
    GROUP BY ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(*) AS total_return_transactions
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_returned_date_sk
),
combined AS (
    SELECT
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(s.total_transactions, 0) AS total_transactions,
        COALESCE(r.total_return_transactions, 0) AS total_return_transactions,
        COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_amount
    FROM sales_by_date s
    FULL JOIN returns_by_date r ON s.date_sk = r.date_sk
)
SELECT
    date_sk,
    total_sales,
    total_returns,
    net_amount,
    total_transactions,
    total_return_transactions,
    CASE WHEN net_amount > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    PERCENT_RANK() OVER (ORDER BY net_amount) AS net_amount_percentile,
    AVG(net_amount) OVER (ORDER BY date_sk ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS moving_avg_14d
FROM combined
WHERE date_sk >= 20230101
ORDER BY net_amount DESC
LIMIT 50
