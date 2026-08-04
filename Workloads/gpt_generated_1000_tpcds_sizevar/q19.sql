WITH filtered_a AS (
   SELECT
       cr.cr_returned_time_sk,
       cr.cr_call_center_sk,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_quantity
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE cr.cr_call_center_sk = 32
     AND cr.cr_return_amount > 500
     AND td.t_hour = 14
),
filtered_b AS (
   SELECT
       cr.cr_returned_time_sk,
       cr.cr_call_center_sk,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_quantity
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE cr.cr_call_center_sk = 31
     AND cr.cr_return_amount < 2000
     AND td.t_hour = 9
),
unioned AS (
   SELECT * FROM filtered_a
   UNION DISTINCT
   SELECT * FROM filtered_b
),
final_agg AS (
   SELECT
       u.cr_call_center_sk,
       td.t_hour,
       SUM(u.cr_return_amount) AS total_return_amount,
       AVG(u.cr_return_tax) AS avg_return_tax,
       COUNT(*) AS cnt_returns,
       MIN(u.cr_return_quantity) AS min_quantity,
       MAX(u.cr_return_quantity) AS max_quantity
   FROM unioned u
   JOIN time_dim td ON u.cr_returned_time_sk = td.t_time_sk
   WHERE u.cr_returned_time_sk IN (
         SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 8 AND 16
   )
   GROUP BY GROUPING SETS (
       (u.cr_call_center_sk, td.t_hour),
       (u.cr_call_center_sk),
       (td.t_hour)
   )
)
SELECT
   cr_call_center_sk,
   t_hour,
   total_return_amount,
   avg_return_tax,
   cnt_returns,
   min_quantity,
   max_quantity
FROM final_agg
ORDER BY total_return_amount DESC
LIMIT 100
