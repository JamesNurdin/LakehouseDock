WITH sales_data AS (
   SELECT
      cc.cc_call_center_id AS call_center_id,
      cc.cc_city AS city,
      SUM(cs.cs_net_profit) AS profit
   FROM tpcds.catalog_sales cs
   JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE cs.cs_list_price > 120
     AND EXISTS (
         SELECT 1
         FROM tpcds.catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
           AND cr.cr_return_amount > 0
     )
   GROUP BY cc.cc_call_center_id, cc.cc_city
   HAVING SUM(cs.cs_net_profit) > 1000
),
return_data AS (
   SELECT
      cc.cc_call_center_id AS call_center_id,
      cc.cc_city AS city,
      -SUM(cr.cr_net_loss) AS profit
   FROM tpcds.catalog_returns cr
   JOIN tpcds.call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cr.cr_return_amount > 50
     AND cr.cr_order_number IN (
         SELECT cs_order_number
         FROM tpcds.catalog_sales
         WHERE cs_list_price > 120
     )
   GROUP BY cc.cc_call_center_id, cc.cc_city
   HAVING SUM(cr.cr_net_loss) > 500
)
SELECT DISTINCT
   call_center_id,
   city,
   profit
FROM (
   SELECT call_center_id, city, profit FROM sales_data
   UNION ALL
   SELECT call_center_id, city, profit FROM return_data
) combined
ORDER BY profit DESC
