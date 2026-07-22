SELECT
  catalog_sales.cs_promo_sk,
  SUM(catalog_sales.cs_ext_sales_price) AS total_sales
FROM
  tpcds.catalog_sales
WHERE
  catalog_sales.cs_sold_date_sk BETWEEN 2450822 AND 2450828
  AND catalog_sales.cs_ext_sales_price > 500
GROUP BY
  catalog_sales.cs_promo_sk
ORDER BY
  total_sales DESC
LIMIT 100
