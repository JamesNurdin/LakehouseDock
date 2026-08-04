SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT inv_item_sk) AS distinct_items
FROM
    tpcds.inventory
WHERE
    inv_date_sk BETWEEN 2451040 AND 2451105
    AND inv_warehouse_sk IN (4, 9, 10)
GROUP BY
    inv_warehouse_sk
ORDER BY
    total_quantity DESC
