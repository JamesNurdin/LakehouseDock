WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns
    WHERE cr_returning_hdemo_sk IN (302, 1206)
      AND cr_returning_cdemo_sk = 700704
      AND cr_item_sk = 115924
      AND cr_return_amount > 1000
    GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_reason_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    sm.sm_type,
    r.r_reason_desc,
    cr_agg.total_return_amount,
    cr_agg.avg_return_tax,
    cr_agg.return_cnt,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
    ) AS max_return_amount_overall
FROM cr_agg
JOIN tpcds.call_center cc
    ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.reason r
    ON cr_agg.cr_reason_sk = r.r_reason_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_type = 'EXPRESS'
  AND r.r_reason_desc LIKE 'Did not%'
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
