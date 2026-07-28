WITH sales_union AS (
   SELECT
      cs_item_sk AS item_sk,
      cs_warehouse_sk AS warehouse_sk,
      cs_net_profit AS net_profit,
      cs_ext_sales_price AS ext_sales_price,
      cs_order_number AS order_number,
      cs_sold_date_sk AS sold_date_sk
   FROM catalog_sales
   UNION ALL
   SELECT
      ws_item_sk AS item_sk,
      ws_warehouse_sk AS warehouse_sk,
      ws_net_profit AS net_profit,
      ws_ext_sales_price AS ext_sales_price,
      ws_order_number AS order_number,
      ws_sold_date_sk AS sold_date_sk
   FROM web_sales
)
SELECT
   w.w_warehouse_id,
   i.i_category,
   CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
   REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})') AS extracted_code,
   SUM(s.net_profit)      AS total_net_profit,
   SUM(s.ext_sales_price) AS total_sales_amount,
   COUNT(DISTINCT s.order_number) AS distinct_orders
FROM sales_union s
JOIN item i ON s.item_sk = i.i_item_sk
JOIN warehouse w ON s.warehouse_sk = w.w_warehouse_sk
WHERE REGEXP_LIKE(i.i_item_desc, '(?i)metal|plastic')
  AND w.w_suite_number LIKE 'Suite %'
  AND SUBSTR(w.w_city, 1, 1) = 'A'
GROUP BY
   w.w_warehouse_id,
   i.i_category,
   i.i_brand,
   i.i_product_name,
   i.i_item_desc
ORDER BY total_net_profit DESC
LIMIT 100
