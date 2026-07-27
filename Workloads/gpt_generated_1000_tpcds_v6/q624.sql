WITH recent_inventory AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY inv_item_sk
)

SELECT *
FROM (
    SELECT
        s.s_store_name,
        i.i_category,
        i.i_brand,
        SUM(sr.sr_net_loss) AS net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
        (SELECT MAX(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category_id = i.i_category_id) AS max_category_price,
        ri.total_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN recent_inventory ri ON i.i_item_sk = ri.inv_item_sk
    WHERE i.i_category_id IN (5, 8)
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY s.s_store_name,
             i.i_category,
             i.i_brand,
             i.i_category_id,
             ri.total_qty
    UNION ALL
    SELECT
        CAST(NULL AS varchar) AS s_store_name,
        i.i_category,
        i.i_brand,
        SUM(wr.wr_net_loss) AS net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
        (SELECT MAX(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category_id = i.i_category_id) AS max_category_price,
        ri.total_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN recent_inventory ri ON i.i_item_sk = ri.inv_item_sk
    WHERE i.i_category_id IN (5, 8)
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY i.i_category,
             i.i_brand,
             i.i_category_id,
             ri.total_qty
) AS combined
ORDER BY net_loss DESC
LIMIT 100
