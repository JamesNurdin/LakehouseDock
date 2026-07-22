SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory
WHERE inv_date_sk = 2451046
  AND inv_quantity_on_hand > 500
GROUP BY inv_warehouse_sk
ORDER BY total_quantity_on_hand DESC
LIMIT 100
