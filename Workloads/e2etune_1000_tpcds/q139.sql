WITH latest_inventory AS (
    SELECT inv_item_sk,
           inv_quantity_on_hand
    FROM (
        SELECT inv_item_sk,
               inv_quantity_on_hand,
               ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
)
SELECT i.i_class,
       r.r_reason_desc,
       SUM(cr.cr_return_quantity) AS total_return_qty,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(cr.cr_return_amount) AS avg_return_amount,
       SUM(cr.cr_fee) AS total_fee,
       SUM(COALESCE(li.inv_quantity_on_hand, 0)) AS latest_inventory_qty,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN latest_inventory li ON i.i_item_sk = li.inv_item_sk
WHERE cr.cr_fee > 20.00
  AND cr.cr_return_tax > 0
  AND cr.cr_returned_time_sk IN (49726, 44830, 34647)
GROUP BY i.i_class, r.r_reason_desc
HAVING SUM(cr.cr_return_quantity) > 100
ORDER BY total_net_loss DESC
LIMIT 50
