WITH sales_by_store_month AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_id, d.d_year, d.d_moy
),
returns_by_store_month AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_net_loss) AS total_returns_loss,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_id, d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.d_year,
    s.d_moy,
    s.total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    s.total_sales_profit - COALESCE(r.total_returns_loss, 0) AS net_profit_after_returns,
    s.sales_transactions,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    rank() OVER (PARTITION BY s.d_year, s.d_moy ORDER BY s.total_sales_profit - COALESCE(r.total_returns_loss, 0) DESC) AS profit_rank
FROM sales_by_store_month s
LEFT JOIN returns_by_store_month r
    ON s.s_store_id = r.s_store_id
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 10
