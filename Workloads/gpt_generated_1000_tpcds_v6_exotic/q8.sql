WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_amount,
        cr_order_number,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_warehouse_sk,
        cr_reason_sk
    FROM catalog_returns cr
    WHERE cr_returned_date_sk BETWEEN 2450870 AND 2451080
      AND cr_return_amount > 50
      AND cr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%price%')
      AND cr_call_center_sk IN (19, 40, 1)
)
SELECT
    cc.cc_name,
    w.w_warehouse_name,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM filtered_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cp.cp_type = 'web'
  AND w.w_state = 'CA'
  AND cc.cc_country = 'United States'
  AND r.r_reason_desc NOT LIKE '%warranty%'
GROUP BY cc.cc_name, w.w_warehouse_name, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
