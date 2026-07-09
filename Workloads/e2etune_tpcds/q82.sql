SELECT t.c_customer_id,
       t.c_last_name,
       t.c_first_name,
       t.total_net_paid,
       t.total_net_profit,
       t.order_count,
       t.avg_quantity,
       RANK() OVER (ORDER BY t.total_net_paid DESC) AS sales_rank
FROM (
   SELECT c.c_customer_id,
          c.c_last_name,
          c.c_first_name,
          SUM(ws.ws_net_paid) AS total_net_paid,
          SUM(ws.ws_net_profit) AS total_net_profit,
          COUNT(*) AS order_count,
          AVG(ws.ws_quantity) AS avg_quantity
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                     AND wp.wp_customer_sk = c.c_customer_sk
   WHERE c.c_birth_country = 'MEXICO'
     AND wp.wp_type = 'Product'
     AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
   GROUP BY c.c_customer_id, c.c_last_name, c.c_first_name
   HAVING SUM(ws.ws_net_paid) > 1000
) t
ORDER BY t.total_net_paid DESC
LIMIT 100
