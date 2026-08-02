WITH intersect_call_centers AS (
    SELECT cr.cr_call_center_sk
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > 500
    INTERSECT
    SELECT cr.cr_call_center_sk
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'DHL'
)

SELECT
    cc.cc_name AS call_center_name,
    sm.sm_carrier,
    DATE_TRUNC('year', d.d_date) AS return_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    CONCAT(cc.cc_state, '-', cc.cc_city) AS state_city,
    suite.suite_num
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(cc.cc_suite_number, '(\\d+)', 1) AS suite_num
) AS suite
WHERE cr.cr_call_center_sk IN (SELECT cr_call_center_sk FROM intersect_call_centers)
  AND cc.cc_name LIKE '%Center%'
  AND regexp_like(cc.cc_name, '^.*Center.*$')
  AND cc.cc_suite_number LIKE '%Suite%'
  AND d.d_year = 2000
GROUP BY
    cc.cc_name,
    sm.sm_carrier,
    DATE_TRUNC('year', d.d_date),
    cc.cc_state,
    cc.cc_city,
    suite.suite_num
ORDER BY total_net_loss DESC
LIMIT 100
