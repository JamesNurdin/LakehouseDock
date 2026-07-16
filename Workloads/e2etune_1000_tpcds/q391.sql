SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_orders,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_ext_discount_amt) AS total_discount,
       SUM(ss.ss_quantity) AS total_quantity,
       COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
       MAX(ss.ss_sold_date_sk) AS last_purchase_date_sk,
       MIN(ss.ss_sold_date_sk) AS first_purchase_date_sk
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1970 AND 1979
  AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
