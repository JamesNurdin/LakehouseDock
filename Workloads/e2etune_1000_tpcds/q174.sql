SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.sm_type,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_store_credit) AS avg_store_credit,
    SUM(CASE WHEN cr.cr_reversed_charge > 500 THEN 1 ELSE 0 END) AS high_rev_charge_cnt,
    ROUND(
        SUM(CASE WHEN cr.cr_reversed_charge > 500 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS pct_high_rev_charge
FROM catalog_returns cr
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_net_loss > 1000
  AND cr.cr_store_credit BETWEEN 10 AND 1000
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, sm.sm_type
HAVING COUNT(*) >= 5
ORDER BY total_return_amount DESC
LIMIT 20
