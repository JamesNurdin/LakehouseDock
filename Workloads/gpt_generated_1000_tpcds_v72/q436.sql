WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_street_name,
        w.w_country,
        i.inv_quantity_on_hand,
        i.inv_item_sk,
        i.inv_warehouse_sk
    FROM
        tpcds.warehouse w
        LEFT OUTER JOIN tpcds.inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_country = 'United States'                -- 1st predicate
        AND w.w_state = 'CA'                          -- 2nd predicate
        AND w.w_city IN ('Los Angeles', 'San Diego') -- 3rd predicate
        AND w.w_street_name LIKE '%Park%'            -- 4th predicate
        AND i.inv_quantity_on_hand BETWEEN 500 AND 800   -- 5th predicate (null‑safe via OR)
        AND (i.inv_quantity_on_hand IS NULL OR i.inv_quantity_on_hand > 0) -- keep null rows from LEFT JOIN
        AND i.inv_item_sk IN (101410, 101444)        -- 6th predicate
        AND EXISTS (
            SELECT 1
            FROM tpcds.inventory i3
            WHERE i3.inv_warehouse_sk = w.w_warehouse_sk
              AND i3.inv_quantity_on_hand > 1000
        )                                            -- subquery predicate
),
warehouse_inventory_with_lateral AS (
    SELECT
        wi.*, 
        lt.total_qty_by_warehouse
    FROM
        warehouse_inventory wi
        CROSS JOIN LATERAL (
            SELECT SUM(i2.inv_quantity_on_hand) AS total_qty_by_warehouse
            FROM tpcds.inventory i2
            WHERE i2.inv_warehouse_sk = wi.inv_warehouse_sk
              AND i2.inv_quantity_on_hand > 500
        ) lt
)
SELECT
    w_id.w_warehouse_id,
    w_id.w_city,
    w_id.w_state,
    w_id.w_street_name,
    SUM(w_id.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(w_id.inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(DISTINCT w_id.inv_item_sk) AS distinct_item_count,
    MIN(w_id.inv_quantity_on_hand) AS min_quantity_on_hand,
    MAX(w_id.inv_quantity_on_hand) AS max_quantity_on_hand,
    w_id.total_qty_by_warehouse
FROM
    warehouse_inventory_with_lateral w_id
GROUP BY
    w_id.w_warehouse_id,
    w_id.w_city,
    w_id.w_state,
    w_id.w_street_name,
    w_id.total_qty_by_warehouse
ORDER BY
    total_quantity_on_hand DESC
LIMIT 100
