SELECT
  wr_returned_date_sk,
  COUNT(DISTINCT wr_order_number) AS distinct_orders
FROM
  web_returns
WHERE
  wr_return_ship_cost > 2000
  AND wr_fee < 25
GROUP BY
  wr_returned_date_sk
ORDER BY
  distinct_orders DESC
LIMIT 100
