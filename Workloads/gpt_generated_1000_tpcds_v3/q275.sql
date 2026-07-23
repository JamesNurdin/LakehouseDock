WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_return_amount > 100.00
      AND cr_return_quantity <= 5
)
SELECT
    cc.cc_name AS call_center_name,
    sm.sm_carrier AS ship_carrier,
    d.d_year AS return_year,
    cp.cp_department AS department,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count,
    MIN(fr.cr_return_tax) AS min_return_tax,
    MAX(fr.cr_return_tax) AS max_return_tax
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_current_year = 'Y'
  AND d.d_first_dom IN (2415202, 2415264)
  AND cc.cc_state = 'CA'
  AND cc.cc_employees >= 100
  AND cp.cp_catalog_number = 4
  AND sm.sm_carrier = 'UPS'
  AND EXISTS (
        SELECT 1
        FROM warehouse w
        WHERE w.w_warehouse_sk = fr.cr_warehouse_sk
          AND w.w_city = 'Spring'
          AND w.w_state = 'CA'
    )
GROUP BY cc.cc_name, sm.sm_carrier, d.d_year, cp.cp_department
ORDER BY total_return_amount DESC
LIMIT 100
