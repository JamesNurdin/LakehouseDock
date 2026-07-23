WITH avg_return AS (
    SELECT cr.cr_call_center_sk,
           AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk
)
SELECT
    w.w_warehouse_name AS warehouse_name,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    (SELECT AVG(avg_return_amount) FROM avg_return) AS overall_avg_return_amount
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_refunded_cash > 500
  AND EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
          AND cc.cc_country = 'United States'
    )
GROUP BY w.w_warehouse_name, r.r_reason_desc
UNION ALL
SELECT
    w.w_warehouse_name AS warehouse_name,
    r.r_reason_desc AS reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    (SELECT AVG(avg_return_amount) FROM avg_return) AS overall_avg_return_amount
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cr.cr_fee > 70
  AND cd.cd_dep_employed_count >= 3
GROUP BY w.w_warehouse_name, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
