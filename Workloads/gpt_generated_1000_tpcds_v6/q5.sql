SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    inv.inv_quantity_on_hand
FROM
    inventory inv
JOIN
    item i
    ON inv.inv_item_sk = i.i_item_sk
WHERE
    inv.inv_quantity_on_hand > 500
    AND i.i_class_id = 3
ORDER BY
    inv.inv_quantity_on_hand DESC
LIMIT 100
