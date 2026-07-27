WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_warehouse_name AS w_warehouse_name,
        w.w_state AS w_state,
        cr.cr_ship_mode_sk,
        sm.sm_type AS sm_type,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk,
        t.t_hour,
        inv.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
        cust.c_preferred_cust_flag
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr.cr_return_amount > 100
      AND cust.c_preferred_cust_flag = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 200
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = cr.cr_item_sk
            AND inv2.inv_warehouse_sk = w.w_warehouse_sk
            AND inv2.inv_quantity_on_hand > 0
      )
),
agg1 AS (
    SELECT
        w_warehouse_name,
        w_state,
        sm_type,
        return_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM base
    GROUP BY w_warehouse_name, w_state, sm_type, return_category
)
SELECT
    w_state,
    AVG(total_return_amount) AS avg_total_return_amount,
    COUNT(*) AS warehouse_shipmode_count
FROM agg1
GROUP BY w_state
HAVING AVG(total_return_amount) > 5000
ORDER BY avg_total_return_amount DESC
LIMIT 100
