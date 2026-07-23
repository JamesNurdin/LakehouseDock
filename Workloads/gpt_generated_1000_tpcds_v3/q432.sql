WITH overall_avg AS (
    SELECT avg(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
)
SELECT
    ca_state,
    sm_type,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(cr_return_amount) > (SELECT avg_return_amount FROM overall_avg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_category
FROM (
    SELECT
        cr.cr_return_amount,
        ca.ca_state,
        sm.sm_type
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE sm.sm_type = 'REGULAR'
      AND hd.hd_vehicle_count >= 2
    UNION ALL
    SELECT
        cr.cr_return_amount,
        ca.ca_state,
        sm.sm_type
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND hd.hd_vehicle_count >= 2
) AS u
GROUP BY ca_state, sm_type
ORDER BY total_return_amount DESC
