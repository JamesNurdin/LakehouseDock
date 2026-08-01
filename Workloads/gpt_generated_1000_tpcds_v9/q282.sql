WITH combined AS (
    SELECT w.w_warehouse_sk,
           w.w_warehouse_id,
           w.w_warehouse_name,
           'return_amount' AS metric_type,
           sum(cr.cr_return_amount) AS metric_value
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_amount > 100.00
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
    UNION ALL
    SELECT w.w_warehouse_sk,
           w.w_warehouse_id,
           w.w_warehouse_name,
           'inventory_qty' AS metric_type,
           sum(inv.inv_quantity_on_hand) AS metric_value
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
)
SELECT c.w_warehouse_id,
       c.w_warehouse_name,
       c.metric_type,
       c.metric_value,
       (SELECT count(DISTINCT cr2.cr_reason_sk)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = c.w_warehouse_sk) AS distinct_return_reasons
FROM combined c
ORDER BY c.w_warehouse_name, c.metric_type
LIMIT 100
