SELECT d.d_year, c.c_customer_id, SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100
