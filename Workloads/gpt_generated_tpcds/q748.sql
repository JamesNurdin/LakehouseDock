WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        i.i_category,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_moy,
        i.i_category
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.d_moy,
    sa.i_category,
    sa.total_sales,
    sa.total_qty,
    sa.total_profit,
    COALESCE(ra.total_return_qty, 0) AS total_return_qty,
    COALESCE(ra.total_refunded, 0) AS total_refunded,
    CASE WHEN sa.total_qty = 0 THEN 0
         ELSE COALESCE(ra.total_return_qty, 0) * 1.0 / sa.total_qty END AS return_rate,
    sa.total_sales - COALESCE(ra.total_refunded, 0) AS net_sales_after_returns,
    sa.total_profit - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
    AND sa.d_year = ra.d_year
    AND sa.d_moy = ra.d_moy
    AND sa.i_category = ra.i_category
WHERE sa.d_year = 2002
ORDER BY net_sales_after_returns DESC
LIMIT 100
