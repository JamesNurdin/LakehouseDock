WITH warehouse_avg AS (
   SELECT w.w_warehouse_sk,
          avg(cs.cs_net_paid) AS avg_net_paid
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_sk
)
SELECT
   concat(cp.cp_department, '-', cp.cp_type) AS dept_type,
   w.w_warehouse_name,
   SUM(cs.cs_net_paid) AS total_net_paid,
   COUNT(*) AS order_cnt,
   AVG(cs.cs_net_paid) AS avg_net_paid,
   (SUM(cs.cs_net_paid) / COUNT(*)) - wa.avg_net_paid AS diff_from_warehouse_avg
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN warehouse_avg wa ON wa.w_warehouse_sk = w.w_warehouse_sk
WHERE
   regexp_like(cp.cp_description, '(?i)new|sale')
   AND ca.ca_city LIKE 'San%'
   AND d.d_fy_year = 1903
   AND w.w_warehouse_name IN (
       SELECT w2.w_warehouse_name
       FROM warehouse w2
       WHERE w2.w_city LIKE 'New%'
   )
GROUP BY
   concat(cp.cp_department, '-', cp.cp_type),
   w.w_warehouse_name,
   wa.avg_net_paid
HAVING
   SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 10
