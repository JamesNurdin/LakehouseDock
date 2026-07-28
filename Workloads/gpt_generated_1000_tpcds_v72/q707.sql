WITH top_store_items AS (
   SELECT i.i_item_sk,
          i.i_product_name,
          SUM(ss.ss_ext_sales_price) AS total_store_sales
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, i.i_product_name
   HAVING SUM(ss.ss_ext_sales_price) > 100000
),
top_web_items AS (
   SELECT i.i_item_sk,
          i.i_product_name,
          SUM(ws.ws_ext_sales_price) AS total_web_sales
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE EXISTS (
        SELECT 1
        FROM warehouse w
        WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
          AND w.w_state = 'CA'
   )
   GROUP BY i.i_item_sk, i.i_product_name
   HAVING SUM(ws.ws_ext_sales_price) > 100000
)

SELECT tsi.i_item_sk,
       tsi.i_product_name,
       'store' AS sales_channel,
       tsi.total_store_sales AS total_sales,
       (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = tsi.i_item_sk) AS return_count
FROM top_store_items tsi

UNION ALL

SELECT twi.i_item_sk,
       twi.i_product_name,
       'web' AS sales_channel,
       twi.total_web_sales AS total_sales,
       (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = twi.i_item_sk) AS return_count
FROM top_web_items twi

ORDER BY total_sales DESC
LIMIT 100
