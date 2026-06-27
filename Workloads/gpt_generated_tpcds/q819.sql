WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date <= DATE '2001-12-31'
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date <= DATE '2001-12-31'
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sa.d_year, ra.d_year) AS year,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_seq,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(sa.total_sales, 0) - COALESCE(ra.total_returns, 0) AS net_revenue,
    COALESCE(sa.sales_transactions, 0) AS sales_txns,
    COALESCE(ra.return_transactions, 0) AS return_txns,
    COALESCE(sa.total_quantity, 0) - COALESCE(ra.total_return_qty, 0) AS net_quantity
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
JOIN store s
    ON COALESCE(sa.ss_store_sk, ra.sr_store_sk) = s.s_store_sk
ORDER BY net_revenue DESC
LIMIT 100
