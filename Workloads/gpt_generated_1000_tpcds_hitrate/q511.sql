WITH recent_returns AS (
    SELECT
        d.d_date AS return_date,
        w.w_warehouse_name AS warehouse_name,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'Zero' END AS metric,
        cr.cr_return_amount AS amount,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_reason_sk = cr.cr_reason_sk
        ) AS avg_reason_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND cp.cp_type = 'Regular'
)
,
no_inventory_returns AS (
    SELECT
        d.d_date AS return_date,
        w.w_warehouse_name AS warehouse_name,
        CASE WHEN cr.cr_return_quantity > 5 THEN 'High' ELSE 'Low' END AS metric,
        cr.cr_return_amount AS amount,
        NULL AS avg_reason_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2022-04-01'
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_date_sk = d.d_date_sk
            AND i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_item_sk = cr.cr_item_sk
      )
)
SELECT return_date, warehouse_name, metric, amount, avg_reason_amount
FROM recent_returns
UNION ALL
SELECT return_date, warehouse_name, metric, amount, avg_reason_amount
FROM no_inventory_returns
ORDER BY return_date DESC, warehouse_name ASC
LIMIT 100
