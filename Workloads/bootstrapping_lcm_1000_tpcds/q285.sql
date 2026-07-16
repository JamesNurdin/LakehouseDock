WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_date_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS total_return_transactions
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returned_date_sk, cr.cr_reason_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_closed.d_date_sk AS store_closed_date_sk,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales_amount,
    sa.total_sales_profit,
    sa.total_sales_transactions,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    COALESCE(ra.total_return_transactions, 0) AS total_return_transactions,
    r.r_reason_desc,
    CASE WHEN sa.total_sales_amount = 0 THEN 0
         ELSE ROUND(100.0 * COALESCE(ra.total_return_amount, 0) / sa.total_sales_amount, 2)
    END AS return_percentage,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales_amount DESC) AS sales_rank_by_year
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN returns_agg ra
    ON ra.cr_returned_date_sk = sa.d_date_sk
LEFT JOIN reason r
    ON ra.cr_reason_sk = r.r_reason_sk
WHERE sa.d_year = 2022
  AND (d_closed.d_date_sk IS NULL OR d_closed.d_year > 2022)
ORDER BY sa.total_sales_amount DESC
LIMIT 100
