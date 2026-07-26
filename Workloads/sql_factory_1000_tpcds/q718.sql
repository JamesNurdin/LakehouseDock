WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS distinct_sales_customers,
        AVG(ss_ext_sales_price) AS avg_sale_price
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr_returning_customer_sk) AS distinct_return_customers,
        MAX(wr_return_amt) AS max_return_amt
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_returned_date_sk
),
combined AS (
    SELECT
        COALESCE(s.date_sk, r.date_sk) AS date_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(s.distinct_sales_customers, 0) AS distinct_sales_customers,
        COALESCE(r.distinct_return_customers, 0) AS distinct_return_customers,
        COALESCE(s.avg_sale_price, 0) AS avg_sale_price,
        COALESCE(r.max_return_amt, 0) AS max_return_amt,
        COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_amount
    FROM sales_by_date s
    FULL OUTER JOIN returns_by_date r ON s.date_sk = r.date_sk
)
SELECT
    date_sk,
    total_sales,
    total_returns,
    distinct_sales_customers,
    distinct_return_customers,
    net_amount,
    avg_sale_price,
    max_return_amt,
    CASE WHEN net_amount >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUM(net_amount) OVER (PARTITION BY DATE_TRUNC('month', DATE_PARSE(CAST(date_sk AS VARCHAR), '%Y%m%d')) ORDER BY date_sk) AS month_cumulative_net,
    ROW_NUMBER() OVER (ORDER BY net_amount DESC) AS net_amount_rank
FROM combined
WHERE date_sk IS NOT NULL
ORDER BY date_sk DESC
LIMIT 200
