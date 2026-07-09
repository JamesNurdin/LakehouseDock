SELECT c.c_customer_id, COUNT(*) AS order_cnt
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY order_cnt DESC
LIMIT 10
