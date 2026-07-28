/* goal: Identify the top three warehouses by total inventory quantity within each state for recent dates, and list distinct warehouses in high‑zip regions for comparison. */
WITH recent_inventory AS (
    SELECT
        i.inv_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS rn_state
    FROM tpcds.inventory i
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_warehouse_sk IN (6, 9, 15)               -- filter 1
      AND i.inv_date_sk BETWEEN 2450800 AND 2451100      -- filter 2
      AND i.inv_quantity_on_hand > 0                    -- filter 3
      AND w.w_state IN ('CA', 'TX', 'NY')               -- filter 4
      AND w.w_zip LIKE '7%'                             -- filter 5
    GROUP BY i.inv_warehouse_sk, w.w_warehouse_id, w.w_state
),
high_zip_warehouses AS (
    SELECT DISTINCT
        w.w_warehouse_id,
        w.w_city,
        w.w_zip,
        CASE
            WHEN w.w_zip LIKE '9%' THEN 'West Coast'
            WHEN w.w_zip LIKE '7%' THEN 'Central'
            ELSE 'Other'
        END AS region
    FROM tpcds.warehouse w
    WHERE (w.w_zip LIKE '7%' OR w.w_zip LIKE '9%')      -- filter 6
      AND w.w_state IN ('CA', 'TX', 'NY')               -- filter 7
      AND w.w_county NOT LIKE '%County'                -- filter 8
)
SELECT *
FROM (
    SELECT
        ri.w_warehouse_id,
        ri.w_state,
        ri.total_qty,
        ri.rn_state,
        NULL AS city,
        NULL AS region
    FROM recent_inventory ri
    WHERE ri.rn_state <= 3                             -- keep top‑3 per state

    UNION ALL

    SELECT
        hzw.w_warehouse_id,
        NULL AS w_state,
        NULL AS total_qty,
        NULL AS rn_state,
        hzw.w_city,
        hzw.region
    FROM high_zip_warehouses hzw
) AS combined
ORDER BY combined.w_warehouse_id,
         combined.rn_state NULLS LAST
