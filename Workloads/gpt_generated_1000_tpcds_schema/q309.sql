SELECT d.d_year,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS cnt_returns
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE cr.cr_return_tax > 10.00
  AND d.d_current_year = 'Y'
GROUP BY d.d_year
ORDER BY d.d_year
