SELECT
  cs.cs_sold_date_sk,
  cs.cs_order_number,
  cs.cs_sales_price,
  i.i_item_id,
  i.i_product_name
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_class_id = 5
  AND cs.cs_sales_price > 50
ORDER BY cs.cs_sales_price DESC
LIMIT 100
