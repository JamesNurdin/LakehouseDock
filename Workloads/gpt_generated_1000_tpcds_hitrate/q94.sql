SELECT i.i_product_name,
       i.i_category,
       SUM(ss.ss_ext_sales_price) AS total_sales
FROM tpcds.store_sales AS ss
JOIN tpcds.item AS i
  ON ss.ss_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
  AND ss.ss_sales_price > 20
GROUP BY i.i_product_name, i.i_category
ORDER BY total_sales DESC
LIMIT 10
