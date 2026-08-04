WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
sales_filtered AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        regexp_like(i.i_item_desc, '[A-Z]{3}')
        AND i.i_units LIKE 'Each%'
    GROUP BY cs.cs_item_sk, i.i_item_id
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM sampled_inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_size LIKE 'small%'
    GROUP BY inv.inv_item_sk, i.i_item_id
),
high_sales AS (
    SELECT i_item_id
    FROM sales_filtered
    WHERE total_net_paid > 5000
),
high_inventory AS (
    SELECT i_item_id
    FROM inventory_agg
    WHERE total_qty_on_hand > 300
),
union_items AS (
    SELECT i_item_id FROM high_sales
    UNION
    SELECT i_item_id FROM high_inventory
),
except_items AS (
    SELECT i_item_id FROM high_sales
    EXCEPT
    SELECT i_item_id FROM high_inventory
),
intersect_items AS (
    SELECT i_item_id FROM high_sales
    INTERSECT
    SELECT i_item_id FROM high_inventory
),
final AS (
    SELECT
        u.i_item_id,
        CASE
            WHEN i.i_item_id IS NOT NULL THEN 'Both'
            WHEN s.i_item_id IS NOT NULL THEN 'SalesOnly'
            ELSE 'InventoryOnly'
        END AS presence,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(inv.total_qty_on_hand, 0) AS total_qty_on_hand,
        (
            SELECT COUNT(*)
            FROM ship_mode sm
            WHERE sm.sm_code LIKE 'A%'
        ) AS air_ship_modes
    FROM union_items u
    LEFT JOIN sales_filtered s ON u.i_item_id = s.i_item_id
    LEFT JOIN inventory_agg inv ON u.i_item_id = inv.i_item_id
    LEFT JOIN intersect_items i ON u.i_item_id = i.i_item_id
)
SELECT
    i_item_id,
    concat(i_item_id, '-', presence) AS item_presence_key,
    presence,
    total_net_paid,
    total_qty_on_hand,
    air_ship_modes
FROM final
ORDER BY total_net_paid DESC, total_qty_on_hand DESC
LIMIT 100
