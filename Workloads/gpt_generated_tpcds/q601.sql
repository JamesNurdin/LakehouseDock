WITH sales AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.total_sales,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    sales.total_profit,
    CASE
        WHEN sales.total_sales = 0 THEN 0
        ELSE COALESCE(returns.total_return_amount, 0) / sales.total_sales
    END AS return_rate
FROM sales
LEFT JOIN returns
    ON sales.ss_store_sk = returns.sr_store_sk
    AND sales.d_year = returns.d_year
    AND sales.d_month_seq = returns.d_month_seq
JOIN store s
    ON sales.ss_store_sk = s.s_store_sk
ORDER BY s.s_store_name, sales.d_year, sales.d_month_seq
