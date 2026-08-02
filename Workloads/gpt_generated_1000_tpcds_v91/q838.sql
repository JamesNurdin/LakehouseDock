WITH item_inventory AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           i.i_category,
           inv.inv_quantity_on_hand
    FROM item i
    FULL OUTER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
),
store_agg AS (
    SELECT ss.ss_item_sk AS item_sk,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
web_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    CASE WHEN GROUPING(ii.i_brand) = 0 THEN ii.i_brand ELSE 'ALL_BRANDS' END AS brand,
    CASE WHEN GROUPING(ii.i_category) = 0 THEN ii.i_category ELSE 'ALL_CATEGORIES' END AS category,
    SUM(COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    MAX(ii.inv_quantity_on_hand) AS max_inventory_qty,
    MAX(REGEXP_EXTRACT(ii.i_product_name, '([A-Z]{2}[0-9]{2})', 1)) AS extracted_code,
    (SELECT MAX(inv_quantity_on_hand) FROM inventory) AS overall_max_inventory
FROM item_inventory ii
LEFT JOIN store_agg sa ON ii.i_item_sk = sa.item_sk
LEFT JOIN web_agg wa ON ii.i_item_sk = wa.item_sk
WHERE ii.i_product_name IS NOT NULL
  AND REGEXP_LIKE(ii.i_product_name, '[A-Z]{2}[0-9]{2}')
  AND ii.i_brand LIKE '%Co%'
  AND EXISTS (
        SELECT 1 FROM web_page wp
        WHERE wp.wp_url LIKE CONCAT('%', SUBSTRING(ii.i_product_name, 1, 5), '%')
          AND wp.wp_type = 'Content'
    )
  AND ii.i_item_sk IN (
        SELECT i1.i_item_sk
        FROM item i1
        WHERE REGEXP_LIKE(i1.i_product_name, '^.*[A-Z]{2}[0-9]{3}.*$')
        INTERSECT
        SELECT inv2.inv_item_sk
        FROM inventory inv2
        WHERE inv2.inv_quantity_on_hand > 0
    )
GROUP BY GROUPING SETS (
    (ii.i_brand, ii.i_category),
    (ii.i_brand),
    (ii.i_category),
    ()
)
ORDER BY brand, category
LIMIT 100
