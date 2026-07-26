WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS distinct_sales_customers
    FROM store_sales
    WHERE ss_sales_price > ss_wholesale_cost
    GROUP BY ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr_returning_customer_sk) AS distinct_return_customers
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
combined AS (
    SELECT
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(s.distinct_sales_customers, 0) AS distinct_sales_customers,
        COALESCE(r.distinct_return_customers, 0) AS distinct_return_customers,
        COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_amount
    FROM sales_by_date s
    FULL JOIN returns_by_date r ON s.date_sk = r.date_sk
)
SELECT
    date_sk,
    total_sales,
    total_returns,
    distinct_sales_customers,
    distinct_return_customers,
    net_amount,
    CASE WHEN net_amount > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUM(net_amount) OVER (ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net,
    DENSE_RANK() OVER (ORDER BY net_amount ASC) AS net_amount_asc_rank,
    LAG(net_amount, 1) OVER (ORDER BY date_sk) AS previous_day_net,
    COALESCE(net_amount - LAG(net_amount, 1) OVER (ORDER BY date_sk), 0) AS net_change_from_prev_day
FROM combined
WHERE total_sales > 0
ORDER BY date_sk
LIMIT 150
