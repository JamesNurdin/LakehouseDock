WITH combined AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc AS descriptor,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_fee > (SELECT MAX(cr2.cr_fee) FROM catalog_returns cr2 WHERE cr2.cr_fee < 30)
      AND cr.cr_return_amount > 0
    GROUP BY w.w_warehouse_name, r.r_reason_desc

    UNION ALL

    SELECT
        w.w_warehouse_name,
        CAST('Inventory' AS varchar) AS descriptor,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(7,2)) AS total_amount,
        CAST(NULL AS decimal(7,2)) AS total_loss,
        COUNT(*) AS cnt
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > (
        SELECT MAX(qty)
        FROM (
            SELECT inv_quantity_on_hand AS qty
            FROM inventory
            WHERE inv_quantity_on_hand < 500
        ) t
    )
    GROUP BY w.w_warehouse_name
)
SELECT
    combined.w_warehouse_name,
    combined.descriptor,
    SUM(combined.total_amount) AS sum_amount,
    SUM(combined.total_loss) AS sum_loss,
    SUM(combined.cnt) AS total_cnt,
    GROUPING(combined.w_warehouse_name) AS g_warehouse,
    GROUPING(combined.descriptor) AS g_descriptor
FROM combined
GROUP BY GROUPING SETS (
    (combined.w_warehouse_name, combined.descriptor),
    (combined.w_warehouse_name),
    (combined.descriptor),
    ()
)
LIMIT 100
