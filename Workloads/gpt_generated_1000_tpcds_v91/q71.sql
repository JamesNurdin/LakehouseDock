SELECT i.i_item_id,
       i.i_product_name,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_quantity) AS total_quantity
FROM item AS i
JOIN store_sales AS ss
  ON ss.ss_item_sk = i.i_item_sk
WHERE i.i_category_id = 3
  AND ss.ss_ext_tax > 50
GROUP BY i.i_item_id, i.i_product_name
ORDER BY total_net_profit DESC
LIMIT 100
