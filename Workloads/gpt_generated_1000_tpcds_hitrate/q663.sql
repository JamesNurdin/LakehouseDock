WITH web_promo_items AS (
       SELECT DISTINCT ws.ws_item_sk
       FROM web_sales ws
       JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
       WHERE regexp_like(p.p_promo_name, '^Holiday')
   ),
   store_promo_items AS (
       SELECT DISTINCT ss.ss_item_sk
       FROM store_sales ss
       JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
       WHERE p.p_promo_name LIKE '%Clearance%'
   ),
   intersect_items AS (
       SELECT ws_item_sk FROM web_promo_items
       INTERSECT
       SELECT ss_item_sk FROM store_promo_items
   ),
   sales_agg AS (
       SELECT
           i.i_category,
           i.i_brand,
           i.i_item_desc,
           p.p_promo_name,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_cnt,
           CONCAT(i.i_item_desc, ' - ', p.p_promo_name) AS desc_promo
       FROM web_sales ws
       JOIN item i ON ws.ws_item_sk = i.i_item_sk
       JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
       JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
       WHERE i.i_item_sk IN (SELECT ws_item_sk FROM intersect_items)
         AND NOT EXISTS (
               SELECT 1
               FROM web_returns wr
               WHERE wr.wr_order_number = ws.ws_order_number
                 AND wr.wr_item_sk = ws.ws_item_sk
         )
         AND regexp_like(i.i_item_desc, '^[A-Z]{3}[0-9]{2}')
         AND i.i_item_desc LIKE '%steel%'
       GROUP BY ROLLUP (i.i_category, i.i_brand, i.i_item_desc, p.p_promo_name)
       HAVING SUM(ws.ws_net_paid) > 0
   )
SELECT
    s.i_category,
    s.i_brand,
    s.i_item_desc,
    s.p_promo_name,
    s.total_net_paid,
    s.total_discount,
    s.sales_cnt,
    s.desc_promo,
    (SELECT MAX(p3.p_cost) FROM promotion p3) AS max_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY s.total_net_paid DESC) AS category_rank
FROM sales_agg s
ORDER BY s.total_net_paid DESC
LIMIT 100
