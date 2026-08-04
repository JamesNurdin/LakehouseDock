SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  COUNT(*) AS orders_count,
  SUM(cs.cs_net_profit) AS total_profit
FROM catalog_sales cs
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_ext_list_price > 5000
  AND c.c_birth_year = 1968
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_profit DESC
LIMIT 10
