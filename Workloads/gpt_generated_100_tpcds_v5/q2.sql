SELECT
    sm.sm_carrier,
    sm.sm_contract,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM tpcds.catalog_returns cr
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier IN ('AIRBORNE', 'MSC')
  AND cr.cr_return_amount > 50
GROUP BY sm.sm_carrier, sm.sm_contract
ORDER BY total_return_amount DESC
LIMIT 100
