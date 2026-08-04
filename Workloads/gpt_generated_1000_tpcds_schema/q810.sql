WITH union_data AS (
   SELECT 
       c.c_customer_sk,
       c.c_customer_id,
       d1.d_year,
       i.i_class,
       cd.cd_education_status,
       SUM(ws.ws_net_profit) AS total_profit,
       RANK() OVER (PARTITION BY d1.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
       CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 'Damaged' ELSE 'Other' END AS reason_category
   FROM store_returns sr
   JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE d1.d_year = 2001
     AND i.i_class = 'maternity'
     AND cd.cd_education_status = 'College'
     AND ws.ws_quantity > 5
   GROUP BY c.c_customer_sk, c.c_customer_id, d1.d_year, i.i_class, cd.cd_education_status, r.r_reason_desc
),
union_data2 AS (
   SELECT 
       c.c_customer_sk,
       c.c_customer_id,
       d2.d_year,
       i.i_class,
       cd.cd_education_status,
       SUM(ws.ws_net_profit) AS total_profit,
       RANK() OVER (PARTITION BY d2.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
       CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 'Damaged' ELSE 'Other' END AS reason_category
   FROM store_returns sr
   JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE d2.d_year = 2002
     AND i.i_class = 'maternity'
     AND cd.cd_education_status = 'College'
     AND ws.ws_quantity > 5
   GROUP BY c.c_customer_sk, c.c_customer_id, d2.d_year, i.i_class, cd.cd_education_status, r.r_reason_desc
),
combined_union AS (
   SELECT * FROM union_data
   UNION DISTINCT
   SELECT * FROM union_data2
),
intersect_customers AS (
   SELECT c.c_customer_sk
   FROM customer c
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_count >= 3
   INTERSECT
   SELECT c.c_customer_sk
   FROM customer c
   JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%damaged%'
)
SELECT 
   cu.c_customer_id,
   cu.d_year,
   cu.i_class,
   cu.cd_education_status,
   cu.total_profit,
   cu.profit_rank,
   cu.reason_category
FROM combined_union cu
JOIN intersect_customers ic ON cu.c_customer_sk = ic.c_customer_sk
ORDER BY cu.total_profit DESC
OFFSET 0 LIMIT 100
