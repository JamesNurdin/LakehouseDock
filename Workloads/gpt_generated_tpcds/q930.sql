WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price)          AS total_sales,
        SUM(ss.ss_quantity)                 AS total_quantity,
        SUM(ss.ss_net_profit)               AS total_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt)      AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    sales_agg.d_year,
    sales_agg.d_month_seq,
    sales_agg.total_sales,
    COALESCE(returns_agg.total_return_amount, 0)                     AS total_return_amount,
    sales_agg.total_profit - COALESCE(returns_agg.total_return_amount, 0) AS net_profit_after_returns,
    (COALESCE(returns_agg.total_return_quantity, 0) * 1.0) / NULLIF(sales_agg.total_quantity, 0) AS return_rate
FROM sales_agg
LEFT JOIN returns_agg
    ON sales_agg.ss_store_sk = returns_agg.sr_store_sk
   AND sales_agg.d_year      = returns_agg.d_year
   AND sales_agg.d_month_seq = returns_agg.d_month_seq
JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
WHERE sales_agg.d_year = 2001
ORDER BY s.s_store_name, sales_agg.d_month_seq
