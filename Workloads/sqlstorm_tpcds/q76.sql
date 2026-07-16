SELECT c.c_customer_id,
       i.i_item_id,
       sum(ss.ss_quantity) AS total_quantity,
       sum(ss.ss_net_paid) AS total_spent
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
GROUP BY c.c_customer_id, i.i_item_id
ORDER BY total_spent DESC
LIMIT 100
