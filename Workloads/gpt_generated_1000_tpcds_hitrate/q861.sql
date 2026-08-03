WITH recent_inventory AS (
    SELECT
        inv_item_sk,
        AVG(inv_quantity_on_hand) AS avg_qty,
        MAX(inv_date_sk) AS max_date_sk
    FROM inventory
    WHERE inv_date_sk >= (
        SELECT MAX(inv_date_sk) - 30 FROM inventory
    )
    GROUP BY inv_item_sk
)
,
high_profit_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING SUM(cs.cs_net_profit) > 10000
)
,
high_inventory_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id
    FROM recent_inventory ri
    JOIN item i ON ri.inv_item_sk = i.i_item_sk
    WHERE ri.avg_qty > 500
      AND EXISTS (
          SELECT 1 FROM promotion pr
          WHERE pr.p_item_sk = i.i_item_sk
            AND pr.p_discount_active = 'Y'
      )
)
SELECT hp.i_item_sk,
       hp.i_item_id
FROM high_profit_items hp
INTERSECT
SELECT hi.i_item_sk,
       hi.i_item_id
FROM high_inventory_items hi
ORDER BY i_item_id
LIMIT 100
