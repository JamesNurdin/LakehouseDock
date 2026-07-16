SELECT r.r_reason_desc,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       SUM(wr.wr_return_amt) AS total_web_return_amount
FROM catalog_returns cr
INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN web_returns wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk = 2451005
  AND wr.wr_returned_date_sk = 2451878
GROUP BY r.r_reason_desc
