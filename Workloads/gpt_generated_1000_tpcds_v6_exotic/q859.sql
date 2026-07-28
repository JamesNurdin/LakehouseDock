WITH per_warehouse_year AS (
    SELECT
        w.w_warehouse_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
        CASE WHEN SUM(cr.cr_return_amount) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND w.w_country = 'United States'
      AND s.s_floor_space > 8000000
      AND cc.cc_gmt_offset BETWEEN -5 AND 0
      AND cc.cc_employees >= 100
      AND cr.cr_return_quantity > 0
      AND cr.cr_returning_cdemo_sk IN (193555, 1264671)
      AND cr.cr_refunded_cdemo_sk NOT IN (29085)
    GROUP BY w.w_warehouse_id, d.d_year
)
SELECT
    d_year,
    SUM(total_return_amount) AS year_total_return,
    AVG(avg_inventory_on_hand) AS year_avg_inventory,
    COUNT(DISTINCT w_warehouse_id) AS warehouse_count,
    MAX(CASE WHEN amount_category = 'HIGH' THEN 1 ELSE 0 END) AS has_high_category
FROM per_warehouse_year
WHERE amount_category = 'HIGH'
GROUP BY d_year
HAVING SUM(total_return_amount) > 500000
ORDER BY year_total_return DESC
LIMIT 100
