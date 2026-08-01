SELECT i.i_brand,
       i.i_category,
       SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_brand = 'exportiimporto #1'
  AND wr.wr_return_ship_cost > 1000.0
GROUP BY i.i_brand, i.i_category
ORDER BY total_return_amount DESC
