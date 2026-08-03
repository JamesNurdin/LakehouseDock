WITH online_items AS (
   SELECT ws.ws_item_sk AS item_sk
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND p.p_discount_active = 'Y'
     AND EXISTS (
         SELECT 1
         FROM web_site wsite
         WHERE wsite.web_site_sk = ws.ws_web_site_sk
           AND wsite.web_gmt_offset = -5.00
     )
),
store_items AS (
   SELECT ss.ss_item_sk AS item_sk
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND ss.ss_quantity > 2
),
common_items AS (
   SELECT item_sk FROM online_items
   INTERSECT
   SELECT item_sk FROM store_items
),
returned_items AS (
   SELECT cr.cr_item_sk AS item_sk
   FROM catalog_returns cr
   WHERE cr.cr_return_amount > 100
),
final_items AS (
   SELECT ci.item_sk
   FROM common_items ci
   EXCEPT
   SELECT ri.item_sk FROM returned_items ri
)
SELECT i.i_item_id,
       i.i_product_name,
       i.i_current_price
FROM final_items fi
JOIN item i ON fi.item_sk = i.i_item_sk
ORDER BY i.i_current_price DESC
LIMIT 100
