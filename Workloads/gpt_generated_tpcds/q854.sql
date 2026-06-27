WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_returns_net_loss,
        SUM(sr.sr_return_quantity) AS total_returns_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns_amt_inc_tax
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    COALESCE(sa.d_year, ra.d_year) AS d_year,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS d_month_seq,
    COALESCE(sa.total_sales_net_paid, 0) AS total_sales_net_paid,
    COALESCE(sa.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sa.total_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(ra.total_returns_net_loss, 0) AS total_returns_net_loss,
    COALESCE(ra.total_returns_quantity, 0) AS total_returns_quantity,
    COALESCE(ra.total_returns_amt_inc_tax, 0) AS total_returns_amt_inc_tax,
    COALESCE(sa.total_sales_net_paid, 0) - COALESCE(ra.total_returns_net_loss, 0) AS net_profit_after_returns
FROM store s
LEFT JOIN sales_agg sa ON s.s_store_sk = sa.ss_store_sk
LEFT JOIN returns_agg ra ON s.s_store_sk = ra.sr_store_sk
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
WHERE sa.d_year IS NOT NULL OR ra.d_year IS NOT NULL
ORDER BY s.s_store_name, COALESCE(sa.d_year, ra.d_year), COALESCE(sa.d_month_seq, ra.d_month_seq)
