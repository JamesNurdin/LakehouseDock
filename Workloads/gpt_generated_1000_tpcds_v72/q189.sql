SELECT
  td.t_sub_shift,
  COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned,
  SUM(wr.wr_return_amt) AS total_return_amt
FROM
  web_returns AS wr
JOIN
  time_dim AS td
  ON wr.wr_returned_time_sk = td.t_time_sk
WHERE
  wr.wr_return_ship_cost > 200.00
  AND td.t_hour BETWEEN 8 AND 18
GROUP BY
  td.t_sub_shift
ORDER BY
  total_return_amt DESC
LIMIT 10
