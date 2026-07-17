SELECT i.i_category,
       SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_rec_end_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
  AND i.i_item_id LIKE 'AAAAAAA%'
GROUP BY i.i_category
ORDER BY total_return_amount DESC
LIMIT 10
