WITH cat_sales AS (
   SELECT
       cs.cs_item_sk AS item_sk,
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS orders,
       (SELECT AVG(inv.inv_quantity_on_hand)
          FROM inventory inv
         WHERE inv.inv_item_sk = cs.cs_item_sk) AS avg_inventory
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE p.p_discount_active = 'Y'
     AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451565
     AND EXISTS (SELECT 1 FROM inventory inv WHERE inv.inv_item_sk = cs.cs_item_sk AND inv.inv_quantity_on_hand > 500)
   GROUP BY cs.cs_item_sk, i.i_item_id, i.i_product_name
),

web_sales AS (
   SELECT
       ws.ws_item_sk AS item_sk,
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS orders,
       (SELECT AVG(inv.inv_quantity_on_hand)
          FROM inventory inv
         WHERE inv.inv_item_sk = ws.ws_item_sk) AS avg_inventory
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE p.p_discount_active = 'Y'
     AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451565
     AND EXISTS (SELECT 1 FROM inventory inv WHERE inv.inv_item_sk = ws.ws_item_sk AND inv.inv_quantity_on_hand > 500)
   GROUP BY ws.ws_item_sk, i.i_item_id, i.i_product_name
)

SELECT
   item_id,
   product_name,
   total_sales,
   orders,
   avg_inventory,
   'catalog' AS source
FROM cat_sales

UNION ALL

SELECT
   item_id,
   product_name,
   total_sales,
   orders,
   avg_inventory,
   'web' AS source
FROM web_sales

ORDER BY total_sales DESC
LIMIT 100
