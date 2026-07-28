SELECT
  store_sales.ss_sold_time_sk,
  SUM(store_sales.ss_net_paid_inc_tax) AS total_paid_inc_tax
FROM tpcds.store_sales AS store_sales
WHERE store_sales.ss_sold_time_sk IN (65495, 55556)
  AND store_sales.ss_net_paid_inc_tax > 30.00
GROUP BY store_sales.ss_sold_time_sk
ORDER BY total_paid_inc_tax DESC
LIMIT 100
