WITH warehouse_inventory AS (
  SELECT
    w.w_warehouse_id,
    w.w_county,
    w.w_state,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(*) AS transaction_cnt
  FROM tpcds.inventory i
  JOIN tpcds.warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.inv_quantity_on_hand BETWEEN 200 AND 900
    AND i.inv_warehouse_sk IN (4, 13, 20, 7)
    AND w.w_county NOT IN ('Bronx County', 'Ziebach County')
    AND w.w_state = 'CA'
    AND w.w_gmt_offset >= -5.00
  GROUP BY w.w_warehouse_id, w.w_county, w.w_state
),
aggregated AS (
  SELECT
    w_county,
    SUM(total_qty) AS county_total_qty,
    AVG(total_qty) AS county_avg_qty,
    COUNT(*) AS warehouse_cnt,
    CASE
      WHEN SUM(total_qty) > 5000 THEN 'Very High'
      WHEN SUM(total_qty) > 3000 THEN 'High'
      ELSE 'Normal'
    END AS county_qty_level
  FROM warehouse_inventory
  GROUP BY w_county
)
SELECT
  w_county,
  county_total_qty,
  county_avg_qty,
  warehouse_cnt,
  county_qty_level
FROM aggregated
WHERE county_total_qty > 1000
  AND warehouse_cnt >= 2
  AND county_qty_level <> 'Normal'
  AND w_county LIKE '%County'
ORDER BY county_total_qty DESC
LIMIT 100
