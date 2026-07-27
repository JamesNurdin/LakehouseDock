WITH enriched_returns AS (
    SELECT DISTINCT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cc.cc_name,
        cc.cc_rec_end_date,
        sm.sm_carrier
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier IN ('MSC', 'ALLIANCE')
)
SELECT
    cc_name,
    sm_carrier,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_tax) AS total_return_tax,
    CASE WHEN SUM(cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS amount_category
FROM enriched_returns
WHERE cc_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
GROUP BY cc_name, sm_carrier

UNION ALL

SELECT
    cc_name,
    sm_carrier,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_tax) AS total_return_tax,
    CASE WHEN SUM(cr_return_amount) > 20000 THEN 'Very High' ELSE 'Moderate' END AS amount_category
FROM enriched_returns
WHERE cc_rec_end_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
GROUP BY cc_name, sm_carrier

ORDER BY amount_category, total_return_amount DESC
LIMIT 100
