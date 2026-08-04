WITH full_inv_wh AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_id,
        w.w_city,
        w.w_warehouse_sq_ft
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
right_ret_date AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year,
        d.d_quarter_name,
        cc.cc_name
    FROM catalog_returns cr
    RIGHT OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1999
)
SELECT *
FROM (
    SELECT
        'InventoryWarehouse' AS source,
        COUNT(DISTINCT inv_item_sk) AS distinct_item_count,
        SUM(DISTINCT inv_quantity_on_hand) AS sum_distinct_quantity,
        COUNT(DISTINCT w_warehouse_id) AS distinct_warehouse_count
    FROM full_inv_wh
    WHERE w_warehouse_sq_ft > 500000

    UNION

    SELECT
        'ReturnDate' AS source,
        COUNT(DISTINCT cr_returned_date_sk) AS distinct_item_count,
        SUM(DISTINCT cr_return_amount) AS sum_distinct_quantity,
        COUNT(DISTINCT cc_name) AS distinct_warehouse_count
    FROM right_ret_date
    WHERE cr_return_amount > 0
) combined
ORDER BY distinct_item_count DESC, source
OFFSET 10 LIMIT 20
