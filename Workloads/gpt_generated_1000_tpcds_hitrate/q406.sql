WITH filtered_returns AS (
  SELECT *
  FROM catalog_returns
  WHERE cr_return_quantity > 1
    AND cr_return_amount BETWEEN 50 AND 1000
    AND cr_return_tax < 200
    AND cr_fee > 0
    AND cr_return_ship_cost NOT BETWEEN 1000 AND 1500
    AND cr_reversed_charge <> 0
),
valid_warehouse AS (
  SELECT *
  FROM warehouse
  WHERE w_state IN ('CA', 'TX', 'NY')
    AND w_gmt_offset = -5.00
    AND w_zip LIKE '5____'
),
intersected_warehouses AS (
  SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'Los Angeles'
  INTERSECT
  SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA'
),
main AS (
  SELECT
    cr.cr_warehouse_sk AS warehouse_sk,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_count,
    MIN(cr.cr_return_ship_cost) AS min_ship_cost,
    MAX(cr.cr_return_ship_cost) AS max_ship_cost,
    CASE
      WHEN SUM(cr.cr_return_amount) > 5000 THEN 'HIGH'
      WHEN SUM(cr.cr_return_amount) > 2000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS amount_category
  FROM filtered_returns cr
  JOIN valid_warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_warehouse_sk IN (SELECT w_warehouse_sk FROM intersected_warehouses)
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = cr.cr_warehouse_sk
          AND cr2.cr_return_quantity = 0
    )
  GROUP BY cr.cr_warehouse_sk, w.w_warehouse_name
)
SELECT *
FROM main
ORDER BY total_return_amount DESC
LIMIT 100
