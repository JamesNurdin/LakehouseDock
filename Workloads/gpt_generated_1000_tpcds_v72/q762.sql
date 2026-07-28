SELECT
    sm.sm_ship_mode_id,
    sm.sm_contract,
    COUNT(DISTINCT cr.cr_return_quantity) AS distinct_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_refunded_cdemo_sk = 1494404
  AND cr.cr_return_amount > 500
  AND sm.sm_contract = 'YvxVaJI10'
GROUP BY sm.sm_ship_mode_id, sm.sm_contract
ORDER BY total_return_amount DESC
LIMIT 100
