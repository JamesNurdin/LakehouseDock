WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales,
    ra.total_return_loss,
    (sa.total_sales - COALESCE(ra.total_return_loss, 0)) AS net_sales_after_returns,
    sa.total_profit,
    (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    sa.num_transactions,
    ra.num_return_transactions
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
ORDER BY sa.s_store_name, sa.d_month_seq
