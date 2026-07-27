WITH agg_returns AS (
    SELECT
        cr_warehouse_sk,
        cr_reason_sk,
        cr_catalog_page_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_return_quantity) AS sum_return_quantity,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_warehouse_sk, cr_reason_sk, cr_catalog_page_sk, cr_call_center_sk
)
SELECT
    w.w_state,
    w.w_warehouse_name,
    w.w_city,
    r.r_reason_desc,
    cp.cp_department,
    SUM(ar.sum_return_amount) AS total_return_amount,
    SUM(ar.sum_return_quantity) AS total_return_quantity,
    COUNT(*) AS num_combinations,
    MIN(ar.sum_return_amount) AS min_return_amount,
    MAX(ar.sum_return_amount) AS max_return_amount,
    (
        SELECT AVG(cr_return_amount)
        FROM catalog_returns
        WHERE cr_return_amount > 0
    ) AS overall_avg_return_amount
FROM agg_returns ar
JOIN warehouse w ON ar.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON ar.cr_reason_sk = r.r_reason_sk
JOIN catalog_page cp ON ar.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc ON ar.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_manager = 'Timothy Bourgeois'
  AND cc.cc_mkt_id IN (1, 3)
  AND w.w_county = 'Fairfield County'
  AND w.w_state = 'CA'
  AND r.r_reason_desc LIKE '%damaged%'
  AND cp.cp_department = 'Electronics'
  AND cp.cp_catalog_page_id IN (
        SELECT cp2.cp_catalog_page_id
        FROM catalog_page cp2
        WHERE cp2.cp_type = 'Online'
    )
GROUP BY w.w_state, w.w_warehouse_name, w.w_city, r.r_reason_desc, cp.cp_department
ORDER BY total_return_amount DESC
LIMIT 100
