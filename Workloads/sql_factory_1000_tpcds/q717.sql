WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS distinct_sales_customers,
        SUM(ss_wholesale_cost) AS total_wholesale_cost
    FROM store_sales
    GROUP BY ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr_returning_customer_sk) AS distinct_return_customers,
        SUM(wr_return_tax) AS total_return_tax
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
        COALESCE(s.total_wholesale_cost, 0) AS total_wholesale_cost,
        COALESCE(r.total_return_tax, 0) AS total_return_tax,
        COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_amount,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) - (COALESCE(s.total_wholesale_cost, 0) + COALESCE(r.total_return_tax, 0)) AS net_profit_estimate
    FROM sales_by_date s
    FULL OUTER JOIN returns_by_date r ON s.date_sk = r.date_sk
)
SELECT
    date_sk,
    total_sales,
    total_returns,
    net_amount,
    net_profit_estimate,
    CASE WHEN net_profit_estimate >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('year', DATE_PARSE(CAST(date_sk AS VARCHAR), '%Y%m%d')) ORDER BY net_profit_estimate DESC) AS yearly_profit_rank,
    AVG(net_profit_estimate) OVER (ORDER BY date_sk ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS moving_avg_30d
FROM combined
WHERE date_sk BETWEEN 20220101 AND 20221231
ORDER BY net_profit_estimate DESC
LIMIT 100
