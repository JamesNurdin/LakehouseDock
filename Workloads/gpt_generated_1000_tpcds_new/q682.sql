WITH store_sales_agg AS (
       SELECT i.i_item_id AS item_id,
              SUM(ss.ss_ext_sales_price) AS total_sales
       FROM store_sales ss
       JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       JOIN item i ON ss.ss_item_sk = i.i_item_sk
       WHERE d.d_year = 2000
       GROUP BY i.i_item_id
     ),
     inventory_agg AS (
       SELECT i.i_item_id AS item_id,
              SUM(inv.inv_quantity_on_hand) AS total_inventory
       FROM inventory inv
       JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
       JOIN item i ON inv.inv_item_sk = i.i_item_sk
       WHERE d.d_year = 2000
       GROUP BY i.i_item_id
     ),
     store_combined AS (
       SELECT COALESCE(ssa.item_id, ia.item_id) AS item_id,
              COALESCE(ssa.total_sales, 0) AS total_sales,
              CASE WHEN COALESCE(ia.total_inventory, 0) = 0 THEN 'No Inventory' ELSE 'Has Inventory' END AS status,
              'store' AS channel
       FROM store_sales_agg ssa
       FULL OUTER JOIN inventory_agg ia
         ON ssa.item_id = ia.item_id
     )
SELECT
    item_id,
    total_sales,
    channel,
    status
FROM store_combined

UNION

SELECT
    i.i_item_id AS item_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    'web' AS channel,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS status
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY i.i_item_id

ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
