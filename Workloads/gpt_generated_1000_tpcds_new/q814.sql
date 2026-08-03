WITH union_pages AS (
   SELECT cp.cp_catalog_page_sk,
          cp.cp_catalog_page_id,
          cp.cp_type,
          SUM(cs.cs_net_profit)                                   AS total_profit,
          CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
   FROM   catalog_page cp
   JOIN   catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN   time_dim td       ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE  td.t_am_pm = 'PM'
     AND  cp.cp_type = 'monthly'
   GROUP BY cp.cp_catalog_page_sk,
            cp.cp_catalog_page_id,
            cp.cp_type
   UNION
   SELECT cp.cp_catalog_page_sk,
          cp.cp_catalog_page_id,
          cp.cp_type,
          -SUM(cr.cr_return_amount)                               AS total_profit,
          CASE WHEN -SUM(cr.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
   FROM   catalog_page cp
   JOIN   catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN   time_dim td         ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE  td.t_am_pm = 'PM'
     AND  cp.cp_type = 'monthly'
   GROUP BY cp.cp_catalog_page_sk,
            cp.cp_catalog_page_id,
            cp.cp_type
),
intersect_pages AS (
   SELECT cp.cp_catalog_page_sk
   FROM   catalog_page cp
   JOIN   catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE  cs.cs_quantity > 5
   INTERSECT
   SELECT cp.cp_catalog_page_sk
   FROM   catalog_page cp
   JOIN   catalog_returns cr ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE  cr.cr_return_quantity > 2
),
excluded_pages AS (
   SELECT DISTINCT cp.cp_catalog_page_sk
   FROM   catalog_page cp
   WHERE  cp.cp_catalog_number IN (1, 2, 3)
)
SELECT up.cp_catalog_page_sk,
       up.cp_catalog_page_id,
       up.cp_type,
       up.total_profit,
       up.profit_level,
       (
         SELECT COUNT(*)
         FROM   catalog_sales cs2
         WHERE  cs2.cs_catalog_page_sk = up.cp_catalog_page_sk
           AND  cs2.cs_sold_date_sk BETWEEN 2450900 AND 2451200
       ) AS sales_days_count
FROM   union_pages up
WHERE  up.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_pages)
  AND  up.cp_catalog_page_sk NOT IN (SELECT cp_catalog_page_sk FROM excluded_pages)
ORDER BY up.total_profit DESC
LIMIT 100
