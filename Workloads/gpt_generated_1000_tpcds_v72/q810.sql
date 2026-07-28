WITH filtered_returns AS (
   SELECT cr.*
   FROM catalog_returns cr
   WHERE cr.cr_store_credit > 100
     AND cr.cr_return_amount >= 50
),
agg_data AS (
   SELECT
       cc.cc_name,
       sm.sm_type,
       COUNT(DISTINCT cr.cr_order_number) AS num_orders,
       SUM(cr.cr_return_amount) AS total_return_amount,
       AVG(cr.cr_return_amount) AS avg_return_amount,
       MAX(cr.cr_return_amount) AS max_return_amount,
       MIN(cr.cr_return_amount) AS min_return_amount
   FROM filtered_returns cr
   JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
       ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c
       ON cr.cr_refunded_customer_sk = c.c_customer_sk
   WHERE cc.cc_mkt_id IN (2, 4)
     AND sm.sm_type = 'EXPRESS'
     AND c.c_birth_country = 'United States'
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
           AND cr2.cr_return_amount > 200
         LIMIT 1
     )
   GROUP BY cc.cc_name, sm.sm_type
   HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    ad.cc_name,
    ad.sm_type,
    ad.num_orders,
    ad.total_return_amount,
    ad.avg_return_amount,
    ad.max_return_amount,
    ad.min_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ad.cc_name ORDER BY ad.total_return_amount DESC) AS rn
FROM agg_data ad
ORDER BY ad.total_return_amount DESC
LIMIT 100
