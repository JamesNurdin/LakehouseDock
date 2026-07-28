WITH base_store AS (
   SELECT DISTINCT
       i.i_item_sk,
       i.i_category,
       i.i_brand,
       i.i_product_name,
       i.i_current_price,
       i.i_color,
       cp.cp_department,
       p.p_promo_name,
       ss.ss_quantity AS qty,
       ss.ss_net_paid AS net_paid,
       ss.ss_net_profit AS net_profit,
       t.t_hour,
       inv.inv_quantity_on_hand,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       r.r_reason_desc
   FROM store_sales ss
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE i.i_current_price > 20
     AND i.i_color = 'Red'
     AND cp.cp_department = 'Sports'
     AND p.p_promo_name LIKE '%Summer%'
     AND t.t_hour BETWEEN 9 AND 17
),

base_web AS (
   SELECT DISTINCT
       i.i_item_sk,
       i.i_category,
       i.i_brand,
       i.i_product_name,
       i.i_current_price,
       i.i_color,
       cp.cp_department,
       p.p_promo_name,
       ws.ws_quantity AS qty,
       ws.ws_net_paid AS net_paid,
       ws.ws_net_profit AS net_profit,
       t.t_hour,
       inv.inv_quantity_on_hand,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       r.r_reason_desc
   FROM web_sales ws
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE i.i_current_price > 20
     AND i.i_color = 'Red'
     AND cp.cp_department = 'Sports'
     AND p.p_promo_name LIKE '%Summer%'
     AND t.t_hour BETWEEN 9 AND 17
),

union_all_sales AS (
   SELECT
       i_item_sk,
       i_category,
       i_brand,
       i_product_name,
       i_current_price,
       i_color,
       cp_department,
       p_promo_name,
       qty,
       net_paid,
       net_profit,
       t_hour,
       inv_quantity_on_hand,
       cr_return_quantity,
       cr_net_loss,
       r_reason_desc
   FROM (
        SELECT * FROM base_store
        UNION ALL
        SELECT * FROM base_web
   )
),

agg1 AS (
   SELECT
       i_category,
       i_brand,
       CASE
           WHEN SUM(net_paid) = 0 THEN 'No Sales'
           WHEN SUM(net_paid) / SUM(inv_quantity_on_hand) > 100 THEN 'High Margin'
           ELSE 'Normal'
       END AS margin_category,
       SUM(qty) AS total_qty,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       COUNT(DISTINCT i_item_sk) AS distinct_items,
       SUM(cr_return_quantity) AS total_return_qty,
       SUM(cr_net_loss) AS total_return_loss
   FROM union_all_sales
   GROUP BY GROUPING SETS (
       (i_category, i_brand),
       (i_category),
       ()
   )
)
SELECT
    i_category,
    i_brand,
    margin_category,
    total_qty,
    total_net_paid,
    total_net_profit,
    distinct_items,
    total_return_qty,
    total_return_loss,
    total_net_paid / NULLIF(distinct_items, 0) AS avg_paid_per_item,
    (SELECT MAX(inv_quantity_on_hand) FROM inventory) AS max_inventory_overall
FROM agg1
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
        WHERE i2.i_category = agg1.i_category
          AND i2.i_brand = agg1.i_brand
          AND cr2.cr_return_quantity > 10
    )
  AND total_net_paid > 1000
ORDER BY total_net_paid DESC
LIMIT 100
