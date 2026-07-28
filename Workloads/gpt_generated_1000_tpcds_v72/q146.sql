WITH warehouse_inventory AS (
    SELECT inv_warehouse_sk,
           AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    t.t_time_id,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_tax) AS min_return_tax,
    MAX(cr.cr_return_amt_inc_tax) AS max_return_inc_tax,
    wi.avg_qty_on_hand
FROM catalog_returns cr
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_inventory wi
    ON w.w_warehouse_sk = wi.inv_warehouse_sk
WHERE t.t_time_id = 'AAAAAAAADBAAAAAA'
  AND t.t_second = 9
  AND w.w_street_name = 'Center '
  AND w.w_warehouse_sq_ft > 800000
  AND cr.cr_store_credit > 500
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_quantity_on_hand > 1000
    )
GROUP BY w.w_warehouse_id, w.w_city, t.t_time_id, wi.avg_qty_on_hand
ORDER BY total_return_amount DESC
LIMIT 100
