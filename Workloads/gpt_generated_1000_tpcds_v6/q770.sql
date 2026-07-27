WITH store_part AS (
   SELECT
       c.c_customer_id AS customer_id,
       'store' AS sales_channel,
       SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
       CASE
           WHEN SUM(ss.ss_net_paid_inc_tax) > 5000 THEN 'HIGH'
           WHEN SUM(ss.ss_net_paid_inc_tax) > 2000 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS sales_category
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_net_paid_inc_tax > 500
     AND ca.ca_state = 'CA'
     AND EXISTS (
         SELECT 1 FROM web_page wp
         WHERE wp.wp_customer_sk = c.c_customer_sk
           AND wp.wp_type = 'HomePage'
     )
   GROUP BY c.c_customer_id
   HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
),
catalog_part AS (
   SELECT
       c.c_customer_id AS customer_id,
       'catalog' AS sales_channel,
       SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
       CASE
           WHEN SUM(cs.cs_net_paid_inc_tax) > 8000 THEN 'HIGH'
           WHEN SUM(cs.cs_net_paid_inc_tax) > 3000 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS sales_category
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE cs.cs_net_paid_inc_tax > 1000
     AND sm.sm_type = 'EXPRESS'
     AND sm.sm_carrier = 'ORIENTAL'
   GROUP BY c.c_customer_id
   HAVING SUM(cs.cs_net_paid_inc_tax) > 2000
)
SELECT
   customer_id,
   sales_channel,
   total_net_paid,
   sales_category
FROM (
   SELECT customer_id, sales_channel, total_net_paid, sales_category FROM store_part
   UNION ALL
   SELECT customer_id, sales_channel, total_net_paid, sales_category FROM catalog_part
) combined
ORDER BY total_net_paid DESC
LIMIT 100
