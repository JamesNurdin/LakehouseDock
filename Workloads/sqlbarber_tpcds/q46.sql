SELECT
    date_dim.d_date,
    date_dim.d_year,
    inventory.inv_item_sk,
    inventory.inv_quantity_on_hand,
    inventory.inv_quantity_on_hand * 745 AS double_quantity,
    CASE
        WHEN inventory.inv_quantity_on_hand > 257 THEN 'InStock'
        ELSE 'LowStock'
    END AS stock_status,
    CASE
        WHEN date_dim.d_day_name = 'Saturday ' THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    inventory.inv_quantity_on_hand - 548 AS adjusted_quantity,
    CASE
        WHEN inventory.inv_quantity_on_hand > 257 THEN
            CASE
                WHEN inventory.inv_quantity_on_hand > 544 THEN 'High'
                ELSE 'Medium'
            END
        ELSE 'Low'
    END AS quantity_category
FROM inventory
JOIN date_dim
    ON inventory.inv_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year = 1903
