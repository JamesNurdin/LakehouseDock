WITH agg_sales AS (
   SELECT
       ss_sold_time_sk,
       ss_item_sk,
       sum(ss_ext_sales_price) AS total_sales,
       sum(ss_net_profit) AS total_profit,
       count(*) AS sales_cnt
   FROM store_sales
   WHERE ss_quantity > 1
     AND ss_wholesale_cost > 10
   GROUP BY ss_sold_time_sk, ss_item_sk
),
intersect_pages AS (
   SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_department = 'Shoes'
   INTERSECT
   SELECT cr_catalog_page_sk FROM catalog_returns WHERE cr_return_quantity > 10
)
SELECT
   cp.cp_department,
   td.t_meal_time,
   td.t_hour,
   a.total_sales,
   a.total_profit,
   cr.cr_return_amount,
   cr.cr_return_quantity,
   rank() OVER (PARTITION BY cp.cp_department ORDER BY a.total_sales DESC) AS dept_sales_rank,
   (SELECT sum(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk) AS page_total_return_amount
FROM agg_sales a
JOIN time_dim td
  ON a.ss_sold_time_sk = td.t_time_sk
JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN intersect_pages ip
  ON cp.cp_catalog_page_sk = ip.cp_catalog_page_sk
WHERE td.t_meal_time IN ('breakfast', 'lunch')
  AND td.t_hour BETWEEN 6 AND 12
  AND cp.cp_type = 'Full'
  AND cr.cr_return_amount > 50
  AND cr.cr_return_quantity <= 30
ORDER BY cp.cp_department, dept_sales_rank, a.total_sales DESC
LIMIT 100
