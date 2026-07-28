/*
  goal: Identify warehouse‑reason pairs for product returns that occurred during business hours and are unique to a single warehouse (no same order returned elsewhere), and combine them with warehouse‑reason pairs for high‑quantity returns outside business hours. Show distinct pairs with aggregated return amount, ordered by warehouse and amount, limited to 100 rows.
*/
WITH business_hour_returns AS (
    SELECT DISTINCT
        w.w_warehouse_name AS warehouse,
        r.r_reason_desc   AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN warehouse w   ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r      ON cr.cr_reason_sk   = r.r_reason_sk
    JOIN time_dim td   ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 200
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cr.cr_order_number
              AND cr2.cr_warehouse_sk <> cr.cr_warehouse_sk
        )
    GROUP BY w.w_warehouse_name, r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 1000
),
outside_hour_high_qty_returns AS (
    SELECT DISTINCT
        w.w_warehouse_name AS warehouse,
        r.r_reason_desc   AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN warehouse w   ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r      ON cr.cr_reason_sk   = r.r_reason_sk
    JOIN time_dim td   ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour NOT BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 5
    GROUP BY w.w_warehouse_name, r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT *
FROM business_hour_returns
UNION ALL
SELECT *
FROM outside_hour_high_qty_returns
ORDER BY warehouse, total_return_amount DESC
LIMIT 100
