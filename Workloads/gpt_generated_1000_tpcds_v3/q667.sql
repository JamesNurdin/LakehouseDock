WITH high_cost AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_ship_cost > 100
      AND sm.sm_carrier = 'FEDEX'
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
)
SELECT
    'HighCost' AS category,
    hc.sm_ship_mode_id,
    hc.sm_carrier,
    hc.total_return_amount,
    hc.total_return_tax,
    hc.total_net_loss,
    hc.return_count
FROM high_cost hc
UNION ALL
SELECT
    'HighAmtIncTax' AS category,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_return_amt_inc_tax > 500
  AND sm.sm_carrier = 'UPS'
GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
ORDER BY total_return_amount DESC
