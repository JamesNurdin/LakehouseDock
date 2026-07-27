SELECT
    cs.cs_order_number,
    cs.cs_sales_price,
    i.i_product_name,
    i.i_brand,
    i.i_size
FROM tpcds.catalog_sales AS cs
JOIN tpcds.item AS i
  ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_brand = 'importoscholar'
  AND i.i_size = 'medium'
  AND cs.cs_sales_price > 20
LIMIT 100
