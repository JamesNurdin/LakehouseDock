WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ds.d_year,
        ds.d_month_seq,
        i.i_category,
        sum(ss.ss_net_paid_inc_tax) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ds.d_year = 2001
    GROUP BY ss.ss_store_sk, ds.d_year, ds.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        sum(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE dr.d_year = 2001
    GROUP BY sr.sr_store_sk, dr.d_year, dr.d_month_seq, i.i_category
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.d_month_seq AS month,
    sa.i_category,
    sa.total_sales,
    sa.total_profit,
    coalesce(ra.total_return_loss, 0) AS total_return_loss,
    sa.total_profit - coalesce(ra.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON ra.sr_store_sk = sa.ss_store_sk
   AND ra.d_year = sa.d_year
   AND ra.d_month_seq = sa.d_month_seq
   AND ra.i_category = sa.i_category
ORDER BY net_profit_after_returns DESC
LIMIT 100
