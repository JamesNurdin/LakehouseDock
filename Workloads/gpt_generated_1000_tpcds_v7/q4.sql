SELECT
    inv_item_sk,
    SUM(inv_quantity_on_hand) AS total_qty
FROM
    inventory
WHERE
    inv_date_sk IN (2450962, 2451046)
    AND inv_warehouse_sk = 7
GROUP BY
    inv_item_sk
ORDER BY
    total_qty DESC
LIMIT 100
