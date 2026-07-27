WITH filtered_returns AS (
   SELECT
       cr.cr_call_center_sk,
       cr.cr_net_loss,
       cr.cr_refunded_cdemo_sk,
       r.r_reason_desc,
       sm.sm_code,
       cc.cc_call_center_id,
       cc.cc_name,
       cc.cc_city,
       cc.cc_state,
       cd.cd_gender
   FROM catalog_returns cr
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE regexp_like(r.r_reason_desc, '(?i)product')
     AND sm.sm_code LIKE 'AIR%'
     AND strpos(cc.cc_name, 'Center') > 0
)
SELECT
   cc.cc_call_center_id,
   cc.cc_name,
   concat(cc.cc_city, ', ', cc.cc_state) AS location,
   SUM(cr.cr_net_loss) AS total_net_loss,
   COUNT(*) AS return_count,
   SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_refund_cnt,
   SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_refund_cnt,
   CASE
       WHEN SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) >= SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) THEN 'M'
       ELSE 'F'
   END AS top_refunded_customer_gender,
   any_value(regexp_extract(r.r_reason_desc, '(product[^.]*?)', 1)) AS extracted_phrase
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE regexp_like(r.r_reason_desc, '(?i)product')
  AND sm.sm_code LIKE 'AIR%'
  AND strpos(cc.cc_name, 'Center') > 0
GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_city, cc.cc_state
ORDER BY total_net_loss DESC
LIMIT 50
