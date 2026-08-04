SELECT
    td.t_sub_shift,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_sub_shift = 'morning'
  AND cr.cr_return_amount > 1000
GROUP BY td.t_sub_shift
ORDER BY total_return_amount DESC
