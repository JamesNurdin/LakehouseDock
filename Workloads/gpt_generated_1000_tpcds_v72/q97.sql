/* goal: Summarize catalog return net loss for the year 2000 by call center manager (containing 'Ray'), extracting numeric codes from catalog page descriptions, and ship mode, showing total loss, distinct order count, and a concatenated manager‑code label. */
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2000
      AND regexp_like(cc.cc_manager, 'Ray')
)
SELECT
    cc.cc_manager,
    regexp_extract(cp.cp_description, '(\\d{3})', 1) AS description_code,
    sm.sm_type,
    SUM(fr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    concat(cc.cc_manager, '-', regexp_extract(cp.cp_description, '(\\d{3})', 1)) AS manager_code
FROM filtered_returns fr
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cp.cp_type LIKE 'A%'
GROUP BY
    cc.cc_manager,
    regexp_extract(cp.cp_description, '(\\d{3})', 1),
    sm.sm_type,
    concat(cc.cc_manager, '-', regexp_extract(cp.cp_description, '(\\d{3})', 1))
ORDER BY total_net_loss DESC
LIMIT 100
