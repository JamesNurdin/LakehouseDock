WITH per_center_mode AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_company,
        cc.cc_county,
        sm.sm_carrier,
        sm.sm_contract,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_fee) AS avg_fee
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_company IN (2, 4, 5, 6)
      AND cc.cc_county LIKE '%County'
      AND sm.sm_carrier IN ('PRIVATECARRIER', 'ORIENTAL', 'AIRBORNE')
      AND cr.cr_fee BETWEEN 20 AND 80
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_company,
        cc.cc_county,
        sm.sm_carrier,
        sm.sm_contract
)
SELECT
    cc_call_center_id,
    cc_company,
    cc_county,
    sm_carrier,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(return_cnt) AS total_returns,
    AVG(avg_fee) AS overall_avg_fee
FROM per_center_mode
GROUP BY
    cc_call_center_id,
    cc_company,
    cc_county,
    sm_carrier
HAVING SUM(total_return_amount) > 10000
ORDER BY overall_avg_fee DESC
LIMIT 100
