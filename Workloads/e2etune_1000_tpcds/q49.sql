WITH returns_by_cc AS (
    SELECT
        cc.cc_division,
        cc.cc_state,
        sm.sm_type AS ship_type,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state IN ('TN', 'GA', 'MI')
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND cr.cr_return_amount > 0
    GROUP BY cc.cc_division, cc.cc_state, sm.sm_type, w.w_warehouse_sk, w.w_warehouse_name
),
inventory_by_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        w.w_city,
        w.w_state,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY w.w_warehouse_sk, w.w_city, w.w_state
),
ranked_returns AS (
    SELECT
        r.cc_division,
        r.cc_state,
        r.ship_type,
        r.w_warehouse_name,
        r.total_return_amount,
        r.avg_net_loss,
        r.return_cnt,
        r.total_return_qty,
        i.avg_inventory_qty,
        (r.total_return_amount / NULLIF(i.avg_inventory_qty, 0)) AS return_to_inventory_ratio,
        ROW_NUMBER() OVER (PARTITION BY r.cc_state ORDER BY r.total_return_amount DESC) AS rn
    FROM returns_by_cc r
    JOIN inventory_by_warehouse i ON r.w_warehouse_sk = i.w_warehouse_sk
)
SELECT
    cc_division,
    cc_state,
    ship_type,
    w_warehouse_name,
    total_return_amount,
    avg_net_loss,
    return_cnt,
    total_return_qty,
    avg_inventory_qty,
    return_to_inventory_ratio
FROM ranked_returns
WHERE rn <= 5
ORDER BY cc_state, total_return_amount DESC
