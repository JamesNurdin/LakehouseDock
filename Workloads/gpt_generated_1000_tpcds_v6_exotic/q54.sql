WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ss.ss_ext_tax,
        wr.wr_return_tax,
        wr.wr_account_credit
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_following_holiday = 'N'
      AND ss.ss_ext_tax > 10
      AND wr.wr_return_tax > 0
      AND wr.wr_account_credit < 500
      AND d.d_month_seq BETWEEN 1 AND 12
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(*) AS txn_cnt
    FROM base
    GROUP BY ROLLUP (d_year, d_month_seq)
)
SELECT
    d_year,
    d_month_seq,
    total_sales,
    total_return_amt,
    total_profit - total_return_loss AS net_contribution,
    CASE
        WHEN total_sales > 100000 THEN 'HIGH'
        WHEN total_sales > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC NULLS LAST) AS sales_rank_month,
    (SELECT AVG(wr_return_amt) FROM tpcds.web_returns) AS overall_avg_return_amt
FROM agg
ORDER BY d_year DESC, d_month_seq DESC NULLS LAST
LIMIT 100
