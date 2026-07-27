WITH catalog_part AS (
   SELECT
      c.c_customer_id        AS customer_id,
      c.c_first_name        AS first_name,
      c.c_last_name         AS last_name,
      cs.cs_order_number    AS order_id,
      cs.cs_net_paid_inc_tax AS sales_amount,
      cc.cc_name            AS source
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE cc.cc_class = 'large'
     AND cs.cs_net_paid_inc_tax > 1000
),
store_part AS (
   SELECT
      c.c_customer_id        AS customer_id,
      c.c_first_name        AS first_name,
      c.c_last_name         AS last_name,
      ss.ss_ticket_number   AS order_id,
      ss.ss_net_paid        AS sales_amount,
      'store_sales'         AS source
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   WHERE ss.ss_ext_wholesale_cost > 3000
     AND c.c_birth_year BETWEEN 1950 AND 1960
)
SELECT
   customer_id,
   first_name,
   last_name,
   order_id,
   sales_amount,
   source
FROM (
   SELECT customer_id, first_name, last_name, order_id, sales_amount, source FROM catalog_part
   UNION ALL
   SELECT customer_id, first_name, last_name, order_id, sales_amount, source FROM store_part
) combined
ORDER BY sales_amount DESC, customer_id
LIMIT 100
