WITH per_warehouse_state AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_ship_cost < 500
      AND hd.hd_income_band_sk IN (5, 13)
      AND ca.ca_state = 'CA'
    GROUP BY w.w_warehouse_id, w.w_state
)
SELECT
    pws.w_warehouse_id,
    pws.w_state,
    pws.total_return_amount,
    pws.total_ship_cost,
    pws.return_cnt,
    pws.total_return_amount / pws.return_cnt AS avg_return_amount_per_return,
    (
        SELECT AVG(total_ship_cost)
        FROM per_warehouse_state
    ) AS overall_avg_ship_cost
FROM per_warehouse_state pws
WHERE pws.total_return_amount > (
        SELECT AVG(total_return_amount)
        FROM per_warehouse_state
    )
ORDER BY pws.total_return_amount DESC
LIMIT 100
