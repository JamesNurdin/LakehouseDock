WITH sales_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_department,
    td.t_hour,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE cc.cc_country = 'United States'
    AND cc.cc_employees > 50
    AND cp.cp_department = 'Electronics'
    AND cs.cs_quantity > 2
    AND ss.ss_quantity > 2
    AND td.t_hour BETWEEN 9 AND 17
  GROUP BY cc.cc_call_center_id, cc.cc_name, cp.cp_department, td.t_hour
  HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
  cc_call_center_id,
  cc_name,
  cp_department,
  t_hour,
  total_catalog_net_paid,
  total_store_net_paid,
  total_net_profit,
  catalog_orders,
  store_tickets,
  RANK() OVER (PARTITION BY cp_department ORDER BY total_net_profit DESC) AS dept_profit_rank,
  (SELECT AVG(total_net_profit) FROM sales_agg) AS avg_profit_all
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
