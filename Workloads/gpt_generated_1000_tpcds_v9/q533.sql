/* Goal: Analyze 2001 sales that had an active promotion for both online (web) and catalog channels, aggregate revenue and quantity per item, classify items by revenue level, and include inventory and promotion presence metrics. */
WITH web_sales_promo AS (
   SELECT 
      ws.ws_item_sk    AS item_sk,
      i.i_item_id     AS item_id,
      i.i_product_name AS product_name,
      i.i_category    AS category,
      SUM(ws.ws_net_paid)   AS net_paid,
      SUM(ws.ws_quantity)   AS quantity,
      'Online'        AS channel
   FROM web_sales ws
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p
     ON p.p_promo_sk = ws.ws_promo_sk
    AND p.p_item_sk = i.i_item_sk
    AND p.p_start_date_sk <= d.d_date_sk
    AND p.p_end_date_sk   >= d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_item_sk, i.i_item_id, i.i_product_name, i.i_category
),
catalog_sales_promo AS (
   SELECT 
      cs.cs_item_sk    AS item_sk,
      i.i_item_id     AS item_id,
      i.i_product_name AS product_name,
      i.i_category    AS category,
      SUM(cs.cs_net_paid)   AS net_paid,
      SUM(cs.cs_quantity)   AS quantity,
      'Catalog'       AS channel
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p
     ON p.p_promo_sk = cs.cs_promo_sk
    AND p.p_item_sk = i.i_item_sk
    AND p.p_start_date_sk <= d.d_date_sk
    AND p.p_end_date_sk   >= d.d_date_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_item_sk, i.i_item_id, i.i_product_name, i.i_category
)
SELECT
   u.item_id,
   u.product_name,
   u.category,
   SUM(u.net_paid)    AS total_net_paid,
   SUM(u.quantity)    AS total_quantity,
   CASE 
      WHEN SUM(u.net_paid) > 10000 THEN 'High'
      ELSE 'Low'
   END                AS revenue_category,
   (
      SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0)
      FROM inventory inv
      WHERE inv.inv_item_sk = u.item_sk
   )                  AS total_inventory_on_hand,
   CASE WHEN EXISTS (
         SELECT 1
         FROM promotion p2
         WHERE p2.p_item_sk = u.item_sk
           AND p2.p_start_date_sk <= (SELECT MAX(d2.d_date_sk) FROM date_dim d2 WHERE d2.d_year = 2001)
           AND p2.p_end_date_sk   >= (SELECT MIN(d3.d_date_sk) FROM date_dim d3 WHERE d3.d_year = 2001)
      ) THEN 1 ELSE 0 END AS has_active_promo_2001
FROM (
   SELECT item_sk, item_id, product_name, category, net_paid, quantity, channel
   FROM web_sales_promo
   UNION ALL
   SELECT item_sk, item_id, product_name, category, net_paid, quantity, channel
   FROM catalog_sales_promo
) u
GROUP BY u.item_id, u.product_name, u.category, u.item_sk
ORDER BY total_net_paid DESC
LIMIT 100
