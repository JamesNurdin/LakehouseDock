WITH recent_inventory AS (
    SELECT inv_item_sk,
           inv_quantity_on_hand
    FROM   inventory
    WHERE  inv_date_sk BETWEEN 2450800 AND 2450900
)
SELECT   i.i_item_id,
         i.i_product_name,
         i.i_formulation,
         SUM(ri.inv_quantity_on_hand) AS total_qty,
         'steel_formulation' AS source
FROM     recent_inventory ri
JOIN     item i
       ON ri.inv_item_sk = i.i_item_sk
WHERE    i.i_formulation LIKE '%steel%'
GROUP BY i.i_item_id,
         i.i_product_name,
         i.i_formulation

UNION ALL

SELECT   i.i_item_id,
         i.i_product_name,
         i.i_formulation,
         SUM(ri.inv_quantity_on_hand) AS total_qty,
         'manager_51_64' AS source
FROM     recent_inventory ri
JOIN     item i
       ON ri.inv_item_sk = i.i_item_sk
WHERE    i.i_manager_id IN (51, 64)
GROUP BY i.i_item_id,
         i.i_product_name,
         i.i_formulation

ORDER BY total_qty DESC
LIMIT 100
