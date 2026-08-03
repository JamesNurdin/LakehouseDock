SELECT ca.ca_city,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
FROM tpcds.store_sales ss
JOIN tpcds.customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ss.ss_ext_wholesale_cost > 1000
  AND ca.ca_state = 'CA'
GROUP BY ca.ca_city
HAVING SUM(ss.ss_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 10
