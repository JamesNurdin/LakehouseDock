WITH filtered_returns AS (
   SELECT DISTINCT
       cr.cr_call_center_sk,
       cr.cr_reason_sk,
       cr.cr_return_amount,
       cr.cr_returned_date_sk
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE regexp_like(cc.cc_name, 'Center')
     AND cp.cp_description LIKE '%special%'
),
aggregated AS (
   SELECT
       cc.cc_call_center_id,
       cc.cc_name,
       cc.cc_city,
       cc.cc_state,
       cc.cc_zip,
       r.r_reason_desc,
       SUM(fr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       SUBSTR(cc.cc_zip, 1, 5) AS zip_prefix
   FROM filtered_returns fr
   JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
   GROUP BY
       cc.cc_call_center_id,
       cc.cc_name,
       cc.cc_city,
       cc.cc_state,
       cc.cc_zip,
       r.r_reason_desc
)
SELECT
    cc_call_center_id,
    cc_name,
    CONCAT(cc_city, ', ', cc_state) AS location,
    r_reason_desc,
    total_return_amount,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_return_amount DESC) AS rn,
    zip_prefix
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
