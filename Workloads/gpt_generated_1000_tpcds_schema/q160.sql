WITH store_data AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       'store' AS sales_channel,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       i.i_current_price
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE t.t_hour = 12
     AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_item_sk = i.i_item_sk
           AND cr.cr_return_quantity > 5
     )
   GROUP BY i.i_item_id, i.i_product_name, i.i_current_price
),
web_data AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       'web' AS sales_channel,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       i.i_current_price
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE t.t_hour = 12
     AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_item_sk = i.i_item_sk
           AND cr.cr_return_quantity > 5
     )
   GROUP BY i.i_item_id, i.i_product_name, i.i_current_price
)
SELECT
    item_id,
    product_name,
    sales_channel,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS rn
FROM (
    SELECT i_item_id AS item_id, i_product_name AS product_name, sales_channel, total_sales FROM store_data
    UNION ALL
    SELECT i_item_id AS item_id, i_product_name AS product_name, sales_channel, total_sales FROM web_data
) combined
ORDER BY sales_channel, rn
