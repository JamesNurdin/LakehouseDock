/*
  Total net loss of catalog returns by call center, month and return reason for the year 2001.
*/
SELECT
    cc.cc_name AS call_center_name,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc AS return_reason,
    COUNT(*) AS return_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND cr.cr_return_quantity > 0
GROUP BY
    cc.cc_name,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc
ORDER BY
    d.d_year,
    d.d_month_seq,
    total_net_loss DESC
