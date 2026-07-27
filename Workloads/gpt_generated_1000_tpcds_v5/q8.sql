SELECT
    i.i_product_name,
    i.i_brand,
    inv.inv_quantity_on_hand,
    inv.inv_warehouse_sk
FROM
    inventory inv
JOIN
    item i
    ON inv.inv_item_sk = i.i_item_sk
WHERE
    i.i_class = 'sports-apparel'
    AND inv.inv_quantity_on_hand > 600
ORDER BY
    inv.inv_quantity_on_hand DESC,
    i.i_product_name
LIMIT 100
