WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_id, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_id, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(sa.s_store_id, ra.s_store_id) AS store_id,
    COALESCE(sa.s_store_sk, ra.s_store_sk) AS store_sk,
    COALESCE(sa.d_year, ra.d_year) AS year,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_seq,
    COALESCE(sa.i_category, ra.i_category) AS category,
    COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
    st.s_store_name
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
    AND sa.i_category = ra.i_category
LEFT JOIN store st
    ON st.s_store_sk = COALESCE(sa.s_store_sk, ra.s_store_sk)
ORDER BY store_id, year, month_seq, category
