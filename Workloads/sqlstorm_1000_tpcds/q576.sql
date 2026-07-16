SELECT cs_sold_date_sk, SUM(cs_ext_sales_price) AS total_sales
FROM catalog_sales
GROUP BY cs_sold_date_sk
ORDER BY total_sales DESC
LIMIT 10
