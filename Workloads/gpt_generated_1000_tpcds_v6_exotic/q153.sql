WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2021
      AND d_month_seq BETWEEN 2400 AND 2420
) 
SELECT
    cp.cp_department,
    sm.sm_type,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_loss
FROM catalog_returns cr
JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc = 'Did not get it on time'
GROUP BY cp.cp_department, sm.sm_type

UNION ALL

SELECT
    cp.cp_department,
    sm.sm_type,
    CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SELECT AVG(cr2.cr_net_loss) FROM catalog_returns cr2) AS overall_avg_loss
FROM catalog_returns cr
JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_birth_month = 7
GROUP BY cp.cp_department, sm.sm_type
ORDER BY total_net_loss DESC
LIMIT 100
