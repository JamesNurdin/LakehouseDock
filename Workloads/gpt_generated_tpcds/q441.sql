WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        SUM(sr.sr_refunded_cash) AS total_refunds,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy, i.i_category
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.month,
    sa.i_category,
    sa.total_sales,
    COALESCE(ra.total_refunds, 0) AS total_refunds,
    sa.total_sales - COALESCE(ra.total_refunds, 0) AS net_revenue,
    sa.total_profit,
    COALESCE(ra.total_loss, 0) AS total_loss,
    sa.total_profit - COALESCE(ra.total_loss, 0) AS profit_after_returns,
    sa.sales_transactions,
    COALESCE(ra.return_transactions, 0) AS return_transactions,
    CASE WHEN sa.sales_transactions = 0 THEN 0
         ELSE CAST(COALESCE(ra.return_transactions, 0) AS double) / sa.sales_transactions
    END AS return_rate
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
    AND sa.d_year = ra.d_year
    AND sa.month = ra.month
    AND sa.i_category = ra.i_category
ORDER BY sa.d_year, sa.month, net_revenue DESC, sa.i_category
