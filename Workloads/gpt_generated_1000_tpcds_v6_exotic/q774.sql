WITH sales_agg AS (
   SELECT 
     d.d_year,
     w.w_city,
     SUM(cs.cs_net_paid) AS total_net_paid,
     SUM(cs.cs_quantity) AS total_quantity,
     COUNT(*) AS order_cnt,
     CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'Large' ELSE 'Small' END AS order_size_category
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY d.d_year, w.w_city
),
returns_agg AS (
   SELECT 
     d.d_year,
     w.w_city,
     SUM(cr.cr_return_amount) AS total_return_amount,
     SUM(cr.cr_return_quantity) AS total_return_quantity,
     COUNT(*) AS return_cnt,
     CASE WHEN SUM(cr.cr_return_quantity) > 50 THEN 'High' ELSE 'Low' END AS return_qty_category
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
   GROUP BY d.d_year, w.w_city
),
combined AS (
   SELECT d_year, w_city, total_net_paid AS amount, order_cnt AS cnt, order_size_category AS cat, 'sales'   AS type
   FROM sales_agg
   UNION ALL
   SELECT d_year, w_city, total_return_amount AS amount, return_cnt AS cnt, return_qty_category AS cat, 'returns' AS type
   FROM returns_agg
),
agg AS (
   SELECT 
     d_year,
     w_city,
     type,
     cat,
     SUM(amount) AS total_amount,
     SUM(cnt)    AS total_cnt
   FROM combined
   GROUP BY GROUPING SETS (
       (d_year, w_city, type, cat),
       (d_year, type, cat),
       (type, cat),
       ()
   )
)
SELECT 
  d_year,
  w_city,
  type,
  cat,
  total_amount,
  total_cnt,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_amount DESC) AS rank_in_year
FROM agg
ORDER BY d_year, type, total_amount DESC
LIMIT 100
