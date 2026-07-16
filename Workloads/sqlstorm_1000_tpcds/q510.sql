SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE d.d_year = 2000
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_sales DESC
LIMIT 10
