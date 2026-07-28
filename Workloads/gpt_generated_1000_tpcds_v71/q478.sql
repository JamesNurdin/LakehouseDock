WITH web_agg AS (
   SELECT c.c_customer_id AS customer_id,
          c.c_first_name,
          c.c_last_name,
          regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
          SUM(ws.ws_net_paid_inc_ship) AS total_spent,
          COUNT(*) AS orders
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE regexp_like(c.c_email_address, '^[A-Za-z]+[0-9]+@')
     AND c.c_first_name LIKE 'A%'
   GROUP BY c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)
),
store_agg AS (
   SELECT c.c_customer_id AS customer_id,
          c.c_first_name,
          c.c_last_name,
          CAST(NULL AS varchar) AS domain,
          SUM(ss.ss_net_paid) AS total_spent,
          COUNT(*) AS orders
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE regexp_like(c.c_email_address, '^[A-Za-z]+[0-9]+@')
     AND p.p_promo_name LIKE '%Clearance%'
   GROUP BY c.c_customer_id,
            c.c_first_name,
            c.c_last_name
)
SELECT customer_id,
       c_first_name,
       c_last_name,
       domain,
       total_spent,
       orders
FROM web_agg
UNION ALL
SELECT customer_id,
       c_first_name,
       c_last_name,
       domain,
       total_spent,
       orders
FROM store_agg
ORDER BY total_spent DESC
LIMIT 100
