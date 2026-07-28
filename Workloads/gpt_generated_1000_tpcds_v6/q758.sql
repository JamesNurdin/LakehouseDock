WITH aggregated_sales AS (
   SELECT
       cp.cp_catalog_page_id,
       cp.cp_department,
       d_sold.d_year,
       d_sold.d_qoy,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 1999
     AND d_sold.d_qoy = 3
     AND cp.cp_department = 'Books'
     AND i.inv_quantity_on_hand > 200
   GROUP BY cp.cp_catalog_page_id, cp.cp_department, d_sold.d_year, d_sold.d_qoy
)
SELECT DISTINCT
   ag.cp_catalog_page_id,
   ag.cp_department,
   ag.d_year,
   ag.total_sales,
   ag.total_profit,
   ag.profit_flag,
   ROW_NUMBER() OVER (PARTITION BY ag.cp_department ORDER BY ag.total_sales DESC) AS dept_sales_rank
FROM aggregated_sales ag
WHERE ag.cp_catalog_page_id IN (
   SELECT cp3.cp_catalog_page_id
   FROM catalog_page cp3
   WHERE cp3.cp_type = 'Classic'
)
ORDER BY ag.total_sales DESC, ag.cp_catalog_page_id
LIMIT 100
