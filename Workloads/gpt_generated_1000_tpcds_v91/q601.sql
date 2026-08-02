WITH filtered_inventory AS (
    SELECT
        inv_warehouse_sk,
        inv_item_sk,
        inv_quantity_on_hand,
        inv_date_sk
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand BETWEEN 200 AND 950
      AND inv_item_sk BETWEEN 101400 AND 101440
      AND inv_warehouse_sk IN (5, 7, 9, 14)
      AND inv_date_sk IN (2450010, 2450011)
),
union_inventory AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM tpcds.warehouse w
    CROSS JOIN LATERAL (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM filtered_inventory fi
        WHERE fi.inv_warehouse_sk = w.w_warehouse_sk
          AND fi.inv_quantity_on_hand > 300
    ) i
    WHERE w.w_state = 'CA'
      AND w.w_gmt_offset = -8.00
      AND w.w_city = 'Los Angeles'
      AND w.w_zip = '90001'

    UNION

    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        i.inv_item_sk,
        i.inv_quantity_on_hand
    FROM tpcds.warehouse w
    CROSS JOIN LATERAL (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM filtered_inventory fi
        WHERE fi.inv_warehouse_sk = w.w_warehouse_sk
          AND fi.inv_quantity_on_hand <= 300
    ) i
    WHERE w.w_state = 'TX'
      AND w.w_gmt_offset = -6.00
      AND w.w_city = 'Dallas'
      AND w.w_zip = '75201'
)
SELECT
    u.w_warehouse_id,
    u.w_city,
    u.w_state,
    SUM(u.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(u.inv_quantity_on_hand) AS avg_quantity_on_hand,
    COUNT(DISTINCT u.inv_item_sk) AS distinct_item_count,
    MIN(u.inv_quantity_on_hand) AS min_quantity_on_hand,
    MAX(u.inv_quantity_on_hand) AS max_quantity_on_hand
FROM union_inventory u
GROUP BY u.w_warehouse_id, u.w_city, u.w_state
ORDER BY total_quantity_on_hand DESC
LIMIT 100
