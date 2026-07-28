WITH promo_returns AS (
   SELECT
       i.i_category AS category,
       SUM(sr.sr_return_amt) AS value,
       'promo_returns' AS source
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   WHERE p.p_response_target > 0
     AND p.p_discount_active = 'Y'
   GROUP BY i.i_category
),
high_inventory AS (
   SELECT
       i.i_category AS category,
       SUM(inv.inv_quantity_on_hand) AS value,
       'high_inventory' AS source
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand > 500
     AND inv.inv_date_sk BETWEEN 2450800 AND 2451100
   GROUP BY i.i_category
)
SELECT category, value, source
FROM promo_returns
UNION ALL
SELECT category, value, source
FROM high_inventory
ORDER BY category, source
LIMIT 100
