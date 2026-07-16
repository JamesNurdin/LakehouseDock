/*
  Monthly net‑profit analysis per store, accounting for returns.
  The query aggregates store sales and store returns by store and month,
  then combines the two aggregates to show profit after returns and the
  profit‑margin for each month.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit)        AS total_sales_profit,
        SUM(ss.ss_net_paid)          AS total_sales_paid
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss)          AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
)
SELECT
    sa.s_store_id,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0)                           AS total_return_loss,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) / NULLIF(sa.total_sales_paid, 0) AS profit_margin
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.d_year      = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
ORDER BY sa.d_year, sa.d_month_seq, profit_margin DESC
