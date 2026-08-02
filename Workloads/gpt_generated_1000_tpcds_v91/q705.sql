SELECT d.d_year AS year,
       'catalog_sales' AS source,
       SUM(cs.cs_ext_sales_price) AS total_amount
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_brand = 'Brand1'
  AND cs.cs_quantity > (SELECT AVG(cs2.cs_quantity) FROM catalog_sales cs2)
GROUP BY d.d_year

UNION ALL

SELECT d.d_year AS year,
       'store_returns' AS source,
       -SUM(sr.sr_return_amt) AS total_amount
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE i.i_brand = 'Brand1'
  AND sr.sr_return_quantity > (SELECT AVG(cs2.cs_quantity) FROM catalog_sales cs2)
GROUP BY d.d_year

ORDER BY year DESC, source
LIMIT 100
