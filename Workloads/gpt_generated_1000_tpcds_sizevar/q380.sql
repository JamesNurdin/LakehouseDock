WITH intersect_items AS (
    SELECT i_item_sk FROM (
        (SELECT i.i_item_sk
         FROM inventory inv
         JOIN item i ON inv.inv_item_sk = i.i_item_sk
         JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
         WHERE inv.inv_quantity_on_hand > 800
           AND w.w_city = 'Seattle')
        UNION
        (SELECT i.i_item_sk
         FROM item i
         WHERE i.i_current_price > 100)
    ) AS u
    INTERSECT
    SELECT i.i_item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit > 2000
      AND ss.ss_coupon_amt > 0
)
SELECT i.i_item_id,
       CASE WHEN i.i_current_price > 150 THEN 'Premium' ELSE 'Standard' END AS price_category,
       COUNT(ss.ss_ticket_number) AS sales_transactions
FROM intersect_items ii
JOIN item i ON ii.i_item_sk = i.i_item_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
GROUP BY i.i_item_id,
         CASE WHEN i.i_current_price > 150 THEN 'Premium' ELSE 'Standard' END
ORDER BY sales_transactions DESC
LIMIT 100
