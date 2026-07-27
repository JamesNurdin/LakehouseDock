WITH wh_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_street_number,
        w.w_street_name,
        w.w_street_type,
        w.w_city,
        w.w_state,
        w.w_zip,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        CONCAT(w.w_street_number, ' ', w.w_street_name, ' ', w.w_street_type, ', ', w.w_city, ', ', w.w_state, ' ', w.w_zip) AS full_address,
        CASE
            WHEN REGEXP_LIKE(w.w_street_name, '(?i)avenue|ave') THEN 1
            WHEN REGEXP_LIKE(w.w_street_type, '(?i)road') THEN 1
            ELSE 0
        END AS has_avenue_or_road
    FROM tpcds.inventory i
    JOIN tpcds.warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND w.w_street_name LIKE '%e%'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_street_number,
        w.w_street_name,
        w.w_street_type,
        w.w_city,
        w.w_state,
        w.w_zip
)
SELECT
    wh.w_warehouse_id,
    wh.w_warehouse_name,
    wh.full_address,
    wh.total_qty,
    wh.distinct_items,
    wh.has_avenue_or_road,
    RANK() OVER (ORDER BY wh.total_qty DESC) AS qty_rank,
    (SELECT AVG(total_qty) FROM wh_inventory) AS avg_total_qty
FROM wh_inventory wh
WHERE wh.total_qty > (SELECT AVG(total_qty) FROM wh_inventory)
  AND EXISTS (
        SELECT 1
        FROM tpcds.inventory i2
        WHERE i2.inv_item_sk = 101444
          AND i2.inv_warehouse_sk = wh.w_warehouse_sk
    )
ORDER BY wh.total_qty DESC
LIMIT 100
