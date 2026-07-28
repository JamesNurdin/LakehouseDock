WITH joined_all AS (
    SELECT
        i.i_category,
        i.i_item_id,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        p.p_cost,
        cc.cc_division_name,
        w.w_warehouse_name,
        td.t_time
    FROM item i
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN time_dim td ON td.t_time_sk = sr.sr_return_time_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
)
SELECT
    i_category,
    cc_division_name,
    store_return_total,
    store_return_qty,
    avg_promo_cost,
    distinct_items,
    min_store_return,
    max_store_return
FROM (
    SELECT
        i_category,
        cc_division_name,
        SUM(sr_return_amt)               AS store_return_total,
        SUM(sr_return_quantity)          AS store_return_qty,
        AVG(p_cost)                      AS avg_promo_cost,
        COUNT(DISTINCT i_item_id)        AS distinct_items,
        MIN(sr_return_amt)               AS min_store_return,
        MAX(sr_return_amt)               AS max_store_return
    FROM joined_all
    WHERE sr_return_quantity > 0
      AND cc_division_name = 'able'
      AND t_time = 12
      AND i_category = 'Electronics'
    GROUP BY i_category, cc_division_name

    UNION ALL

    SELECT
        i_category,
        cc_division_name,
        SUM(cr_return_amount)            AS store_return_total,
        SUM(cr_return_quantity)          AS store_return_qty,
        AVG(p_cost)                      AS avg_promo_cost,
        COUNT(DISTINCT i_item_id)        AS distinct_items,
        MIN(cr_return_amount)            AS min_store_return,
        MAX(cr_return_amount)            AS max_store_return
    FROM joined_all
    WHERE cr_return_quantity > 0
      AND cc_division_name = 'able'
      AND t_time = 12
      AND i_category = 'Electronics'
    GROUP BY i_category, cc_division_name
) AS combined
ORDER BY i_category, store_return_total DESC
