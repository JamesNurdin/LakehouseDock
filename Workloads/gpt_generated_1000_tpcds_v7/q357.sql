WITH item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand_id,
        i.i_current_price,
        i.i_container,
        i.i_color,
        i.i_size,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        inv.inv_date_sk
    FROM
        inventory inv
    JOIN
        item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE
        inv.inv_quantity_on_hand > 200
        AND i.i_current_price BETWEEN 10 AND 150
        AND i.i_brand_id IN (3001002, 8015002, 1003001)
        AND i.i_container LIKE '%Box%'
        AND i.i_color = 'Red'
        AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
),
agg AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        i_brand_id,
        i_current_price,
        i_container,
        i_color,
        i_size,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        CASE
            WHEN i_current_price > 50 THEN 'expensive'
            ELSE 'affordable'
        END AS price_category
    FROM item_inventory
    GROUP BY
        i_item_sk,
        i_item_id,
        i_category,
        i_brand_id,
        i_current_price,
        i_container,
        i_color,
        i_size
)
SELECT
    i_item_sk,
    i_item_id,
    i_category,
    i_brand_id,
    i_current_price,
    i_container,
    i_color,
    i_size,
    total_quantity_on_hand,
    price_category,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_quantity_on_hand DESC) AS category_rank
FROM agg
ORDER BY total_quantity_on_hand DESC
LIMIT 100
