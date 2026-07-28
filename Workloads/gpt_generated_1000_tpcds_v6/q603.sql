WITH item_info AS (
    SELECT i_item_sk,
           i_item_id,
           i_product_name,
           i_current_price
    FROM   item
    WHERE  i_current_price BETWEEN 10 AND 500
)
SELECT   ii.i_item_id,
         ii.i_product_name,
         'store' AS sales_channel,
         SUM(ss.ss_ext_sales_price) AS total_sales,
         COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
         CASE WHEN SUM(ss.ss_ext_sales_price) >= 50000 THEN 'high' ELSE 'low' END AS sales_level
FROM     store_sales ss
JOIN     item_info ii ON ss.ss_item_sk = ii.i_item_sk
GROUP BY ii.i_item_id,
         ii.i_product_name

UNION ALL

SELECT   ii.i_item_id,
         ii.i_product_name,
         'web' AS sales_channel,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         COUNT(DISTINCT ws.ws_order_number) AS order_count,
         CASE WHEN SUM(ws.ws_ext_sales_price) >= 50000 THEN 'high' ELSE 'low' END AS sales_level
FROM     web_sales ws
JOIN     item_info ii ON ws.ws_item_sk = ii.i_item_sk
GROUP BY ii.i_item_id,
         ii.i_product_name

ORDER BY total_sales DESC
LIMIT 100
