WITH filtered_returns AS (
   SELECT
       cr.cr_return_amount,
       cr.cr_order_number,
       cc.cc_name,
       cc.cc_company,
       cc.cc_hours,
       td.t_shift,
       td.t_sub_shift,
       cd_ref.cd_education_status
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
   WHERE cc.cc_company = 4
     AND cc.cc_hours = '8AM-4PM'
     AND td.t_shift = 'first'
     AND td.t_sub_shift = 'morning'
     AND cd_ref.cd_education_status = 'College'
     AND cr.cr_return_amount > 500
), agg AS (
   SELECT
       cc_name,
       t_shift,
       t_sub_shift,
       COUNT(*) AS num_returns,
       SUM(cr_return_amount) AS total_return_amount,
       AVG(cr_return_amount) AS avg_return_amount,
       MIN(cr_return_amount) AS min_return_amount,
       MAX(cr_return_amount) AS max_return_amount,
       COUNT(DISTINCT cr_order_number) AS distinct_orders
   FROM filtered_returns
   GROUP BY cc_name, t_shift, t_sub_shift
   HAVING COUNT(*) > 5
), final AS (
   SELECT
       a.*,
       ROW_NUMBER() OVER (PARTITION BY a.cc_name ORDER BY a.total_return_amount DESC) AS rn,
       (SELECT COUNT(*) FROM call_center cc2 WHERE cc2.cc_company = 4 AND cc2.cc_hours = '8AM-4PM') AS total_cc_matching
   FROM agg a
)
SELECT DISTINCT
   cc_name,
   t_shift,
   t_sub_shift,
   num_returns,
   total_return_amount,
   avg_return_amount,
   min_return_amount,
   max_return_amount,
   distinct_orders,
   rn,
   total_cc_matching
FROM final
WHERE rn <= 3
ORDER BY total_return_amount DESC
LIMIT 100
