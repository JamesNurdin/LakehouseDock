WITH
  returns_data AS (
    SELECT
      d.d_year,
      r.r_reason_desc AS reason_desc,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm.sm_type = 'AIR'
      )
    GROUP BY d.d_year, r.r_reason_desc
  ),
  inventory_data AS (
    SELECT
      d.d_year,
      'Inventory' AS source,
      SUM(i.inv_quantity_on_hand) AS total_quantity,
      COUNT(*) AS inventory_cnt
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
          AND cr.cr_return_amount > 0
      )
    GROUP BY d.d_year
  )
SELECT
  combined.d_year,
  combined.category,
  SUM(combined.total_return_amount) AS total_return_amount,
  SUM(combined.return_cnt) AS return_cnt,
  SUM(combined.total_quantity) AS total_quantity,
  SUM(combined.inventory_cnt) AS inventory_cnt,
  AVG(combined.avg_return_amount_year) AS avg_return_amount_year
FROM (
  SELECT
    r.d_year,
    r.reason_desc AS category,
    r.total_return_amount,
    r.return_cnt,
    CAST(NULL AS INTEGER) AS total_quantity,
    CAST(NULL AS INTEGER) AS inventory_cnt,
    (
      SELECT AVG(cr2.cr_return_amount)
      FROM catalog_returns cr2
      JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
      WHERE d2.d_year = r.d_year
    ) AS avg_return_amount_year
  FROM returns_data r

  UNION ALL

  SELECT
    i.d_year,
    i.source AS category,
    CAST(NULL AS DECIMAL(7,2)) AS total_return_amount,
    CAST(NULL AS INTEGER) AS return_cnt,
    i.total_quantity,
    i.inventory_cnt,
    (
      SELECT AVG(cr2.cr_return_amount)
      FROM catalog_returns cr2
      JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
      WHERE d2.d_year = i.d_year
    ) AS avg_return_amount_year
  FROM inventory_data i
) AS combined
GROUP BY GROUPING SETS (
  (combined.d_year, combined.category),
  (combined.d_year),
  ()
)
ORDER BY combined.d_year DESC, combined.category
LIMIT 100
