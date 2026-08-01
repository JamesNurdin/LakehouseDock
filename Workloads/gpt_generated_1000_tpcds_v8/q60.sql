SELECT
  r.r_reason_desc,
  SUM(cr.cr_net_loss) AS total_net_loss
FROM
  catalog_returns cr
JOIN
  reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE
  cr.cr_return_tax > 50
  AND r.r_reason_desc = 'Did not get it on time'
GROUP BY
  r.r_reason_desc
ORDER BY
  total_net_loss DESC
