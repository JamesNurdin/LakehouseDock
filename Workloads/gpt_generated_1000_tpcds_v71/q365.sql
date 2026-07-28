WITH sales AS (
   SELECT
       cs.cs_order_number,
       cp.cp_department,
       cp.cp_type,
       cp.cp_description,
       t.t_hour,
       cs.cs_ext_sales_price,
       cs.cs_net_profit
   FROM catalog_sales cs
   JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE cp.cp_type LIKE '%monthly%'
     AND regexp_like(cp.cp_description, '(?i)sale|discount')
),
returns AS (
   SELECT
       wr.wr_order_number,
       t.t_hour AS return_hour,
       wr.wr_net_loss
   FROM web_returns wr
   JOIN time_dim t
       ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE wr.wr_return_amt > 50
)
SELECT
   s.cp_department,
   s.cp_type,
   s.t_hour,
   COUNT(DISTINCT s.cs_order_number) AS orders_sold,
   SUM(s.cs_ext_sales_price) AS total_sales,
   SUM(s.cs_net_profit) AS total_profit,
   SUM(CASE WHEN s.cs_net_profit > 1000 THEN 1 ELSE 0 END) AS high_profit_orders,
   SUM(r.wr_net_loss) AS total_return_loss,
   CONCAT('Dept_', s.cp_department) AS dept_key
FROM sales s
LEFT JOIN returns r
   ON s.cs_order_number = r.wr_order_number
   AND s.t_hour = r.return_hour
GROUP BY
   s.cp_department,
   s.cp_type,
   s.t_hour,
   CONCAT('Dept_', s.cp_department)
ORDER BY total_profit DESC
LIMIT 100
