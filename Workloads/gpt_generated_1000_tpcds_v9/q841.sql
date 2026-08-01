WITH time_categories AS (
    SELECT t_time_sk,
           CASE 
               WHEN t_hour BETWEEN 9 AND 17 THEN 'Business'
               WHEN t_hour BETWEEN 0 AND 8 THEN 'Early'
               ELSE 'Late'
           END AS time_category
    FROM time_dim
),
union_sales AS (
    SELECT 
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        'Store' AS source,
        s.s_store_name AS location,
        SUM(ss.ss_quantity) AS total_quantity,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High' ELSE 'Low' END AS qty_category,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = i.i_item_sk) AS max_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_categories tc ON ss.ss_sold_time_sk = tc.t_time_sk
    WHERE tc.time_category = 'Business'
      AND EXISTS (
          SELECT 1 FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 500
      )
    GROUP BY i.i_item_id, i.i_item_desc, s.s_store_name, i.i_item_sk
    UNION ALL
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        'Catalog' AS source,
        cc.cc_name AS location,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High' ELSE 'Low' END AS qty_category,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = i.i_item_sk) AS max_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_categories tc ON cs.cs_sold_time_sk = tc.t_time_sk
    WHERE tc.time_category = 'Business'
      AND i.i_item_sk IN (
          SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500
      )
    GROUP BY i.i_item_id, i.i_item_desc, cc.cc_name, i.i_item_sk
)
SELECT 
    item_id,
    item_desc,
    source,
    location,
    total_quantity,
    qty_category,
    max_price
FROM union_sales
ORDER BY total_quantity DESC, item_id
LIMIT 100
