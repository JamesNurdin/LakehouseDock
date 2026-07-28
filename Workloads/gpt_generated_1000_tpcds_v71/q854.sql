WITH inv_by_state AS (
    SELECT
        i.i_category AS category,
        w.w_state   AS location,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'                -- example state filter
      AND i.i_formulation LIKE '%steel%'
    GROUP BY i.i_category, w.w_state
),
inv_by_city AS (
    SELECT
        i.i_category AS category,
        w.w_city    AS location,
        SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Lincoln'            -- example city filter
      AND i.i_category = 'Men'
    GROUP BY i.i_category, w.w_city
)
SELECT category, location, total_qty
FROM inv_by_state
UNION ALL
SELECT category, location, total_qty
FROM inv_by_city
ORDER BY category, total_qty DESC
