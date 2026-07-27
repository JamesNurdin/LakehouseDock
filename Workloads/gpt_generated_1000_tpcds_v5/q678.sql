WITH base AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_gmt_offset,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS sum_cr_return_amount,
        COUNT(*) AS cnt_cr,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS sum_inv_qty,
        COALESCE(SUM(sr.sr_return_amt), 0) AS sum_sr_return_amt,
        COUNT(sr.sr_return_amt) AS cnt_sr
    FROM catalog_returns cr
    INNER JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    WHERE
        cr.cr_return_amount > 0
        AND cr.cr_return_quantity >= 1
        AND inv.inv_quantity_on_hand IS NOT NULL
        AND w.w_gmt_offset = -5.00
        AND r.r_reason_desc <> 'Other'
        AND sm.sm_type = 'AIR'
    GROUP BY
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        r.r_reason_desc,
        w.w_warehouse_name,
        w.w_gmt_offset,
        sm.sm_type
)
SELECT
    reason_desc,
    warehouse_name,
    ship_mode_type,
    total_return_amount,
    total_inventory_qty,
    CASE
        WHEN total_return_amount > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_category
FROM (
    SELECT
        r_reason_desc AS reason_desc,
        w_warehouse_name AS warehouse_name,
        sm_type AS ship_mode_type,
        sum_cr_return_amount + sum_sr_return_amt AS total_return_amount,
        sum_inv_qty AS total_inventory_qty,
        (sum_cr_return_amount + sum_sr_return_amt) / NULLIF(cnt_cr + cnt_sr, 0) AS avg_return_per_txn
    FROM base
) t
WHERE avg_return_per_txn > 5
ORDER BY total_return_amount DESC
LIMIT 100
