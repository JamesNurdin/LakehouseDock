WITH filtered_returns AS (
    SELECT
        cc.cc_name,
        cc.cc_city,
        cc.cc_manager,
        sm.sm_ship_mode_id,
        sm.sm_ship_mode_sk,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(sm.sm_ship_mode_id, '^AAAAA')
      AND c.c_email_address LIKE '%mail%'
)
SELECT
    CONCAT(fr.cc_name, ', ', fr.cc_city) AS call_center_location,
    fr.sm_ship_mode_id,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(fr.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS return_category,
    SUBSTRING(fr.cc_manager FROM 1 FOR 5) AS manager_prefix,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_ship_mode_sk = fr.sm_ship_mode_sk) AS avg_return_amt_for_ship_mode
FROM filtered_returns fr
GROUP BY fr.cc_name, fr.cc_city, fr.cc_manager, fr.sm_ship_mode_id, fr.sm_ship_mode_sk
ORDER BY total_return_amount DESC
LIMIT 100
