SELECT d.d_date,
       SUM(cr.cr_net_loss) AS total_net_loss
FROM tpcds.catalog_returns cr
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-01-31'
  AND cr.cr_return_quantity > 0
GROUP BY d.d_date
ORDER BY d.d_date
