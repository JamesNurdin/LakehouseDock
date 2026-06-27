WITH store_sales_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY s.s_store_sk, d.d_year
),
store_returns_agg AS (
    SELECT
        s.s_store_sk AS store_sk,
        d.d_year AS year,
        SUM(sr.sr_refunded_cash) AS total_refund,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY s.s_store_sk, d.d_year
)
SELECT
    s.s_store_name,
    sa.year,
    sa.total_sales,
    sr_agg.total_refund,
    (sa.total_sales - COALESCE(sr_agg.total_refund, 0.0)) AS net_sales,
    sa.total_profit,
    (sa.total_profit - COALESCE(sr_agg.total_loss, 0.0)) AS net_profit,
    sa.sales_cnt,
    sr_agg.return_cnt
FROM store_sales_agg sa
LEFT JOIN store_returns_agg sr_agg
    ON sa.store_sk = sr_agg.store_sk AND sa.year = sr_agg.year
JOIN store s ON sa.store_sk = s.s_store_sk
ORDER BY sa.year DESC, net_sales DESC
