WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_street_type,
        SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state IN ('CA', 'TX', 'NY')
      AND w.w_street_type IN ('Street', 'Drive', 'Way')
      AND w.w_city IS NOT NULL
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_street_type
    HAVING SUM(COALESCE(i.inv_quantity_on_hand, 0)) > 500
),

item_counts AS (
    SELECT
        i.inv_item_sk,
        COUNT(DISTINCT w.w_warehouse_sk) AS warehouse_cnt,
        SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS item_total_qty
    FROM inventory i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 300
      AND w.w_state = 'CA'
      AND w.w_street_type = 'Street'
    GROUP BY i.inv_item_sk
    HAVING COUNT(DISTINCT w.w_warehouse_sk) >= 1
)

SELECT *
FROM (
    SELECT
        wi.w_warehouse_name AS entity_name,
        wi.total_qty,
        wi.distinct_items,
        (
            SELECT COUNT(*)
            FROM item_counts ic
            WHERE ic.item_total_qty > wi.total_qty
        ) AS higher_item_cnt
    FROM warehouse_inventory wi
    WHERE EXISTS (
        SELECT 1
        FROM inventory i_sub
        WHERE i_sub.inv_warehouse_sk = wi.w_warehouse_sk
          AND i_sub.inv_quantity_on_hand > 600
    )
    UNION
    SELECT
        CAST(ic.inv_item_sk AS VARCHAR) AS entity_name,
        ic.item_total_qty AS total_qty,
        ic.warehouse_cnt AS distinct_items,
        (
            SELECT COUNT(*)
            FROM warehouse_inventory wi_sub
            WHERE wi_sub.total_qty > ic.item_total_qty
        ) AS higher_warehouse_cnt
    FROM item_counts ic
) combined
WHERE combined.total_qty IS NOT NULL
GROUP BY combined.entity_name, combined.total_qty, combined.distinct_items, combined.higher_item_cnt
HAVING combined.total_qty > 400
ORDER BY combined.total_qty DESC
LIMIT 100
