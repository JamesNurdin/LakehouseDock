WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        sd.d_year,
        sd.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_sales_quantity
    FROM store_sales ss
    JOIN date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE sd.d_year = 2001
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, sd.d_year, sd.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        rd.d_year,
        rd.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE rd.d_year = 2001
    GROUP BY sr.sr_store_sk, sr.sr_item_sk, rd.d_year, rd.d_month_seq, i.i_category
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.i_category,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    sa.total_sales_profit - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
    sa.total_sales_quantity,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
   AND sa.ss_item_sk = ra.sr_item_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
   AND sa.i_category = ra.i_category
JOIN store s ON sa.ss_store_sk = s.s_store_sk
ORDER BY net_profit_after_returns DESC
LIMIT 20
