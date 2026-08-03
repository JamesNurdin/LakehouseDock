WITH cc_ship AS (
   SELECT
       cc.cc_name AS category,
       sm.sm_type AS subcategory,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE sm.sm_ship_mode_id = 'AAAAAAAADAAAAAAA'
     AND cc.cc_mkt_id = 3
   GROUP BY cc.cc_name, sm.sm_type
),
cust_ret AS (
   SELECT
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS category,
       cd.cd_gender AS subcategory,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE sm.sm_contract = 'OrDuVy2H'
   GROUP BY c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT category, subcategory, total_return_amount, return_cnt
FROM cc_ship
UNION
SELECT category, subcategory, total_return_amount, return_cnt
FROM cust_ret
ORDER BY total_return_amount DESC, return_cnt ASC
OFFSET 0 LIMIT 100
