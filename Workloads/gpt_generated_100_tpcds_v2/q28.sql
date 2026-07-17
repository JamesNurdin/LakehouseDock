SELECT i.i_brand,
       i.i_category,
       SUBSTRING(i.i_product_name, 1, 8) AS product_name_prefix,
       CONCAT('Brand ', CAST(i.i_brand AS VARCHAR)) AS brand_label,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       SUM(cs.cs_net_profit) AS total_net_profit,
       AVG(cs.cs_net_profit) AS avg_net_profit,
       AVG(LENGTH(i.i_product_name)) AS avg_product_name_length
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE i.i_item_desc LIKE '%pink%'
  AND ca.ca_address_id LIKE 'AAAAAAA%'
GROUP BY i.i_brand,
         i.i_category,
         SUBSTRING(i.i_product_name, 1, 8),
         CONCAT('Brand ', CAST(i.i_brand AS VARCHAR))
ORDER BY total_net_profit DESC
LIMIT 20
