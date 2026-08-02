WITH start_year_pages AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        (
            SELECT MAX(i2.inv_quantity_on_hand)
            FROM inventory i2
            WHERE i2.inv_date_sk = d.d_date_sk
        ) AS max_quantity
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND d.d_quarter_name = '1900Q3'
      AND cp.cp_type = 'C'
)
SELECT
    sp.cp_catalog_page_id,
    sp.cp_department,
    sp.cp_catalog_number,
    sp.max_quantity
FROM start_year_pages sp
INTERSECT
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    (
        SELECT MAX(i3.inv_quantity_on_hand)
        FROM inventory i3
        WHERE i3.inv_date_sk = d_end.d_date_sk
    ) AS max_quantity
FROM catalog_page cp
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk = d_end.d_date_sk
      AND w.w_county = 'Richland County'
      AND i.inv_quantity_on_hand > 100
)
  AND d_end.d_current_week = 'N'
ORDER BY cp_catalog_page_id
LIMIT 100
