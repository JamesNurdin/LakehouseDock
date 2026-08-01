WITH sampled_cr AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_reason_sk,
        cr_return_amount,
        cr_return_tax,
        cr_return_quantity,
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_order_number
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
reason_only_in_web AS (
    SELECT wr_reason_sk
    FROM web_returns
    EXCEPT
    SELECT cr_reason_sk
    FROM catalog_returns
)
SELECT
    cc.cc_company_name,
    sm.sm_type,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_return_tax) AS sum_return_tax,
    SUM(wr.wr_return_amt) AS sum_web_return_amt,
    COUNT(*) AS total_returns,
    AVG(l.avg_wr_amount_for_reason) AS avg_web_return_amt_by_reason,
    (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount_overall
FROM sampled_cr cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
    SELECT AVG(wr2.wr_return_amt) AS avg_wr_amount_for_reason
    FROM web_returns wr2
    WHERE wr2.wr_reason_sk = r.r_reason_sk
) AS l
WHERE cc.cc_state = 'CA'
  AND cc.cc_company_name = 'able'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc = 'Gift exchange'
  AND cr.cr_return_quantity > 1
  AND cr.cr_return_amount > 1000
  AND wr.wr_return_amt > 200
  AND r.r_reason_sk NOT IN (SELECT wr_reason_sk FROM reason_only_in_web)
GROUP BY ROLLUP (cc.cc_company_name, sm.sm_type, r.r_reason_desc)
ORDER BY cc.cc_company_name, sm.sm_type, r.r_reason_desc
