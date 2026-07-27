WITH
  store_agg AS (
    SELECT ss.ss_item_sk AS item_sk,
           SUM(ss.ss_ext_sales_price) AS store_sales
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  web_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_ext_sales_price) AS web_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
  ),
  sales_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales,
           ROW_NUMBER() OVER (ORDER BY COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN store_agg s ON s.item_sk = i.i_item_sk
    LEFT JOIN web_agg w ON w.item_sk = i.i_item_sk
    WHERE COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) > 10000
  ),
  inventory_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(inv.inv_quantity_on_hand) AS total_inventory,
           ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS inventory_rank
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(inv.inv_quantity_on_hand) > 5000
  )
SELECT
  i_item_id,
  i_product_name,
  total_sales AS metric,
  sales_rank AS rank,
  'sales' AS source
FROM sales_agg
UNION ALL
SELECT
  i_item_id,
  i_product_name,
  total_inventory AS metric,
  inventory_rank AS rank,
  'inventory' AS source
FROM inventory_agg
ORDER BY metric DESC
LIMIT 100
