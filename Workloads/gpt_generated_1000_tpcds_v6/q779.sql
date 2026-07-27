WITH base AS (
   SELECT
       d.d_year,
       d.d_date,
       t.t_meal_time,
       cp.cp_department,
       s.s_store_name,
       s.s_state,
       cs.cs_order_number,
       cs.cs_net_paid,
       cr.cr_return_amount,
       ws.ws_order_number,
       ws.ws_net_paid,
       wr.wr_return_amt,
       'catalog' AS channel
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   LEFT JOIN web_sales ws
          ON ws.ws_sold_date_sk = d.d_date_sk
         AND ws.ws_sold_time_sk = t.t_time_sk
   LEFT JOIN web_returns wr
          ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
   WHERE d.d_year = 2001
     AND t.t_meal_time = 'dinner'
     AND cp.cp_department = 'Electronics'
     AND s.s_state = 'CA'
),
catalog_agg AS (
   SELECT
       d_year,
       cp_department,
       s_store_name,
       SUM(cs_net_paid) AS sales_amount,
       SUM(cr_return_amount) AS return_amount,
       COUNT(DISTINCT cs_order_number) AS order_cnt,
       ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(cs_net_paid) DESC) AS dept_rank
   FROM base
   WHERE channel = 'catalog'
   GROUP BY ROLLUP (d_year, cp_department, s_store_name)
),
web_agg AS (
   SELECT
       d_year,
       cp_department,
       s_store_name,
       SUM(ws_net_paid) AS sales_amount,
       SUM(wr_return_amt) AS return_amount,
       COUNT(DISTINCT ws_order_number) AS order_cnt,
       ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(ws_net_paid) DESC) AS dept_rank
   FROM base
   WHERE channel = 'web'
   GROUP BY CUBE (d_year, cp_department, s_store_name)
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY d_year DESC, sales_amount DESC
LIMIT 100
