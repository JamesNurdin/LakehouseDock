WITH sales_agg AS (
    SELECT
        s.s_store_id,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY s.s_store_id, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_id,
        i.i_category,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY s.s_store_id, i.i_category
)
SELECT
    COALESCE(sa.s_store_id, ra.s_store_id) AS store_id,
    COALESCE(sa.i_category, ra.i_category) AS category,
    COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amount, 0) AS net_sales,
    COALESCE(sa.total_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_profit
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
    AND sa.i_category = ra.i_category
ORDER BY net_profit DESC
LIMIT 20
