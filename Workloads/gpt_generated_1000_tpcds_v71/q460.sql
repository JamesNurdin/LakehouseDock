WITH agg AS (
   SELECT
      cc.cc_name,
      i.i_category,
      i.i_item_sk,
      cp.cp_catalog_number,
      td.t_hour,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      AVG(cr.cr_return_amount) AS avg_return_amount
   FROM catalog_returns cr
   JOIN time_dim td
     ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE
      td.t_hour BETWEEN 9 AND 18                              -- predicate 1
      AND i.i_class IN ('hockey', 'pants')                     -- predicate 2
      AND cp.cp_catalog_number IN (4, 6, 10)                  -- predicate 3
      AND cc.cc_mkt_desc LIKE '%free%'                        -- predicate 4
      AND cr.cr_returned_date_sk >= 2450000                    -- predicate 5
   GROUP BY ROLLUP (cc.cc_name, i.i_category, i.i_item_sk, cp.cp_catalog_number, td.t_hour)
   HAVING SUM(cr.cr_return_amount) > 0
)
SELECT
   cc_name,
   i_category,
   i_item_sk,
   cp_catalog_number,
   t_hour,
   total_return_amount,
   total_return_qty,
   avg_return_amount,
   ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_return_amount DESC) AS rn,
   CASE WHEN total_return_amount > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS return_level,
   EXISTS (SELECT 1 FROM catalog_returns cr3 WHERE cr3.cr_item_sk = agg.i_item_sk AND cr3.cr_return_amount > 5000) AS has_big_return
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
