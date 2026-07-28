WITH
  store_data AS (
    SELECT
      r.r_reason_id AS reason_id,
      SUM(sr.sr_net_loss) AS total_net_loss,
      'store' AS return_source
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451800 AND 2452000
      AND hd.hd_dep_count >= 6
    GROUP BY r.r_reason_id
  ),
  catalog_data AS (
    SELECT
      r.r_reason_id AS reason_id,
      SUM(cr.cr_net_loss) AS total_net_loss,
      'catalog' AS return_source
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451800 AND 2452000
      AND hd.hd_dep_count >= 6
      AND cc.cc_state = 'CA'
    GROUP BY r.r_reason_id
  )
SELECT reason_id, total_net_loss, return_source
FROM store_data
UNION ALL
SELECT reason_id, total_net_loss, return_source
FROM catalog_data
ORDER BY reason_id, return_source
