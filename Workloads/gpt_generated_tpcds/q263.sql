WITH store_sales_monthly AS (
    SELECT
        store.s_store_id AS store_id,
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        sum(ss.ss_net_paid) AS total_sales_net_paid,
        sum(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN store ON ss.ss_store_sk = store.s_store_sk
    JOIN date_dim ON ss.ss_sold_date_sk = date_dim.d_date_sk
    GROUP BY store.s_store_id, date_dim.d_year, date_dim.d_month_seq
),
store_returns_monthly AS (
    SELECT
        store.s_store_id AS store_id,
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        sum(sr.sr_net_loss) AS total_return_net_loss,
        sum(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN store ON sr.sr_store_sk = store.s_store_sk
    JOIN date_dim ON sr.sr_returned_date_sk = date_dim.d_date_sk
    GROUP BY store.s_store_id, date_dim.d_year, date_dim.d_month_seq
)
SELECT
    ss.store_id,
    ss.year,
    ss.month_seq,
    ss.total_sales_net_paid,
    ss.total_sales_net_profit,
    coalesce(sr.total_return_net_loss, 0) AS total_return_net_loss,
    ss.total_sales_net_profit - coalesce(sr.total_return_net_loss, 0) AS net_profit_after_returns
FROM store_sales_monthly ss
LEFT JOIN store_returns_monthly sr
    ON ss.store_id = sr.store_id
    AND ss.year = sr.year
    AND ss.month_seq = sr.month_seq
ORDER BY ss.store_id, ss.year, ss.month_seq
