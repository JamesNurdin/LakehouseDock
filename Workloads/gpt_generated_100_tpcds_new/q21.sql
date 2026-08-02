SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS orders_count
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'MEXICO'
  AND cs.cs_sales_price > 100
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_net_profit DESC
LIMIT 10
