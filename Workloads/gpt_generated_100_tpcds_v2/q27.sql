SELECT
  i.i_category,
  SUM(sr.sr_return_amt) AS total_return_amount
FROM
  store_returns sr
JOIN
  item i
  ON sr.sr_item_sk = i.i_item_sk
WHERE
  i.i_rec_start_date >= DATE '2001-01-01'
  AND i.i_rec_start_date < DATE '2002-01-01'
GROUP BY
  i.i_category
ORDER BY
  total_return_amount DESC
LIMIT 10
