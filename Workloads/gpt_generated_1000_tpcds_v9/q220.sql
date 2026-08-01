WITH high_warehouses AS (
    SELECT i.inv_warehouse_sk
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.inv_warehouse_sk
    HAVING SUM(i.inv_quantity_on_hand) > 5000
)
SELECT
    w.w_warehouse_sk AS warehouse_sk,
    w.w_warehouse_name AS warehouse_name,
    d.d_month_seq AS month_seq,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    CASE WHEN SUM(i.inv_quantity_on_hand) > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS quantity_category,
    'Period_A' AS period_label
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN high_warehouses hw ON i.inv_warehouse_sk = hw.inv_warehouse_sk
WHERE d.d_year = 2001 AND d.d_month_seq = 8
GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_month_seq
HAVING SUM(i.inv_quantity_on_hand) > 500
UNION ALL
SELECT
    w.w_warehouse_sk AS warehouse_sk,
    w.w_warehouse_name AS warehouse_name,
    d.d_month_seq AS month_seq,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    CASE WHEN SUM(i.inv_quantity_on_hand) > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS quantity_category,
    'Period_B' AS period_label
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN high_warehouses hw ON i.inv_warehouse_sk = hw.inv_warehouse_sk
WHERE d.d_year = 2001 AND d.d_month_seq = 9
GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_month_seq
HAVING SUM(i.inv_quantity_on_hand) > 500
ORDER BY warehouse_sk, month_seq
LIMIT 100
