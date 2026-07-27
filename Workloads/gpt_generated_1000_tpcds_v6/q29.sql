WITH inventory_snapshot AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1202  -- first quarter of 2001 (example)
    GROUP BY w.w_warehouse_name, d.d_year, d.d_month_seq
)
SELECT
    d_year,
    w_warehouse_name,
    reason_category,
    total_return_amount,
    return_cnt,
    return_level
FROM (
    SELECT
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        r.r_reason_desc AS reason_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(cr.cr_return_amount) > (
                SELECT AVG(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
            ) THEN 'High'
            ELSE 'Low'
        END AS return_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%Defective%'
      AND EXISTS (
          SELECT 1
          FROM inventory_snapshot inv
          WHERE inv.w_warehouse_name = w.w_warehouse_name
            AND inv.d_year = d.d_year
      )
    GROUP BY d.d_year, w.w_warehouse_name, r.r_reason_desc, cr.cr_returned_date_sk

    UNION ALL

    SELECT
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        r.r_reason_desc AS reason_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(cr.cr_return_amount) > (
                SELECT AVG(cr2.cr_return_amount)
                FROM catalog_returns cr2
                WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
            ) THEN 'High'
            ELSE 'Low'
        END AS return_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%Customer%'
      AND EXISTS (
          SELECT 1
          FROM inventory_snapshot inv
          WHERE inv.w_warehouse_name = w.w_warehouse_name
            AND inv.d_year = d.d_year
      )
    GROUP BY d.d_year, w.w_warehouse_name, r.r_reason_desc, cr.cr_returned_date_sk
) AS combined_results
ORDER BY d_year, w_warehouse_name, total_return_amount DESC
LIMIT 100
