/*
  Goal: Analyze catalog returns by ship mode, focusing on returns whose reason description mentions a price issue.
  The query demonstrates string processing with REGEXP_LIKE, LIKE pattern matching, CONCAT, and a CASE expression.
  It aggregates return amounts and net loss per ship mode, categorizes loss levels, and limits the output.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_call_center_sk,
        r.r_reason_id,
        r.r_reason_desc,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_contract,
        cc.cc_name
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price')
      AND sm.sm_ship_mode_id LIKE 'AAAAAAA%'
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(fr.cr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    MAX(CONCAT(fr.r_reason_id, '-', sm.sm_ship_mode_id)) AS reason_ship_key
FROM filtered_returns fr
JOIN ship_mode sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_code
ORDER BY
    total_net_loss DESC
LIMIT 100
