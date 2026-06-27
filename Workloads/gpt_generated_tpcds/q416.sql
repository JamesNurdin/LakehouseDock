WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ds.d_year,
        ds.d_moy AS month,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    GROUP BY ss.ss_store_sk, ds.d_year, ds.d_moy
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        dr.d_year,
        dr.d_moy AS month,
        SUM(sr.sr_net_loss) AS total_returns_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY sr.sr_store_sk, dr.d_year, dr.d_moy
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.month,
    sa.total_sales_profit,
    COALESCE(ra.total_returns_loss, 0) AS total_returns_loss,
    (sa.total_sales_profit - COALESCE(ra.total_returns_loss, 0)) AS net_profit_after_returns,
    sa.sales_transactions,
    COALESCE(ra.return_transactions, 0) AS return_transactions
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
    AND sa.d_year = ra.d_year
    AND sa.month = ra.month
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
WHERE sa.d_year = 2001
ORDER BY s.s_store_name, sa.d_year, sa.month
