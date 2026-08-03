WITH sub_a AS (
   SELECT
       c.c_customer_id,
       cp.cp_catalog_page_id,
       SUM(cs.cs_net_paid)               AS total_spent,
       (SELECT COUNT(*) FROM customer)   AS total_customers,
       ld.avg_discount
   FROM (
       SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
   ) cs
   RIGHT OUTER JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   LEFT JOIN LATERAL (
       SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
       FROM catalog_sales cs2
       WHERE cs2.cs_order_number = cs.cs_order_number
   ) ld ON true
   WHERE cs.cs_ext_list_price > 3000
   GROUP BY c.c_customer_id, cp.cp_catalog_page_id, ld.avg_discount
),
sub_b AS (
   SELECT
       c.c_customer_id,
       cp.cp_catalog_page_id,
       SUM(cs.cs_net_paid)               AS total_spent,
       (SELECT COUNT(*) FROM customer)   AS total_customers,
       ld.avg_discount
   FROM catalog_sales cs
   RIGHT OUTER JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c
       ON cs.cs_ship_customer_sk = c.c_customer_sk
   LEFT JOIN LATERAL (
       SELECT AVG(cs2.cs_ext_discount_amt) AS avg_discount
       FROM catalog_sales cs2
       WHERE cs2.cs_order_number = cs.cs_order_number
   ) ld ON true
   WHERE sm.sm_code = 'AIR' AND i.i_class_id IN (15, 16)
   GROUP BY c.c_customer_id, cp.cp_catalog_page_id, ld.avg_discount
),
cross_set AS (
   SELECT region
   FROM (VALUES 'NorthAmerica', 'Europe', 'Asia') AS t(region)
)
SELECT
   a.c_customer_id,
   a.cp_catalog_page_id,
   a.total_spent,
   a.total_customers,
   a.avg_discount,
   r.region
FROM (
   SELECT * FROM sub_a
   INTERSECT
   SELECT * FROM sub_b
) a
CROSS JOIN cross_set r
ORDER BY a.total_spent DESC
LIMIT 100
