WITH distinct_cc AS (
    SELECT DISTINCT
        cc.cc_call_center_sk,
        cc.cc_state,
        cc.cc_market_manager,
        cc.cc_gmt_offset
    FROM call_center cc
    WHERE cc.cc_state IN ('CA', 'NY', 'TX')
      AND cc.cc_gmt_offset BETWEEN -8 AND -5
)
SELECT
    dc.cc_state,
    dc.cc_market_manager,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    COUNT(*) AS num_returns,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    ROW_NUMBER() OVER (
        PARTITION BY dc.cc_state
        ORDER BY SUM(cr.cr_return_amount) DESC
    ) AS state_row_num,
    RANK() OVER (
        ORDER BY SUM(cr.cr_return_amount) DESC
    ) AS overall_rank,
    ROW_NUMBER() OVER (
        ORDER BY SUM(cr.cr_return_amount) DESC
    ) AS overall_row_num,
    (
        SELECT COUNT(DISTINCT cp2.cp_department)
        FROM catalog_page cp2
        JOIN catalog_returns cr2 ON cp2.cp_catalog_page_sk = cr2.cr_catalog_page_sk
        WHERE cr2.cr_call_center_sk = dc.cc_call_center_sk
    ) AS distinct_departments_for_cc,
    (
        SELECT SUM(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = dc.cc_call_center_sk
    ) AS total_return_amount_for_cc
FROM catalog_returns cr
JOIN distinct_cc dc
    ON cr.cr_call_center_sk = dc.cc_call_center_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
      AND cp.cp_description LIKE '%goods%'
      AND cp.cp_catalog_page_number IN (5, 12, 19)
      AND cp.cp_type IS NOT NULL
)
  AND cr.cr_return_amount > 100
  AND cr.cr_fee BETWEEN 20 AND 80
  AND cr.cr_return_quantity BETWEEN 1 AND 5
  AND cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
  AND cr.cr_return_ship_cost > 0
GROUP BY ROLLUP (dc.cc_state, dc.cc_market_manager, dc.cc_call_center_sk)
ORDER BY total_return_amount DESC
LIMIT 100
