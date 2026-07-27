WITH first_year AS (
   SELECT
       w.w_warehouse_name,
       sm.sm_type,
       SUM(cr.cr_return_amount) AS year_return_amount,
       (SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk) AS total_warehouse_return
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
   GROUP BY w.w_warehouse_name, sm.sm_type, w.w_warehouse_sk
),
second_year AS (
   SELECT
       w.w_warehouse_name,
       sm.sm_type,
       SUM(cr.cr_return_amount) AS year_return_amount,
       (SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk) AS total_warehouse_return
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2002
     AND cc.cc_county = 'Jackson County'
     AND EXISTS (
         SELECT 1
         FROM reason r
         WHERE r.r_reason_sk = cr.cr_reason_sk
           AND r.r_reason_desc = 'Customer Not Interested'
     )
   GROUP BY w.w_warehouse_name, sm.sm_type, w.w_warehouse_sk
)
SELECT *
FROM first_year
UNION ALL
SELECT *
FROM second_year
LIMIT 100
