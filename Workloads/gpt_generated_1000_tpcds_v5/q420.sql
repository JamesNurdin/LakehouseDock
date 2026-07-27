WITH avg_fee_by_reason AS (
    SELECT cr_reason_sk, AVG(cr_fee) AS avg_fee
    FROM catalog_returns
    GROUP BY cr_reason_sk
)
SELECT
    cc.cc_name,
    i.i_category,
    r.r_reason_desc,
    td.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    COUNT(*) AS return_cnt,
    MIN(cr.cr_return_amount) AS min_return,
    MAX(cr.cr_return_amount) AS max_return
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN avg_fee_by_reason afr ON cr.cr_reason_sk = afr.cr_reason_sk
WHERE cc.cc_manager = 'Gregory Altman'
  AND td.t_am_pm = 'PM'
  AND i.i_category = 'Electronics'
  AND cr.cr_fee > 20
  AND td.t_sub_shift = 'evening'
  AND cr.cr_fee > afr.avg_fee
  AND cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
    )
GROUP BY cc.cc_name, i.i_category, r.r_reason_desc, td.t_hour
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
