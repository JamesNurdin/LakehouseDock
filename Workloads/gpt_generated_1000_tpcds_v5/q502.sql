SELECT i.i_item_id,
       i.i_product_name,
       SUM(w.wr_return_amt) AS total_return_amt,
       COUNT(*) AS return_cnt
FROM tpcds.item i
JOIN tpcds.web_returns w
  ON w.wr_item_sk = i.i_item_sk
WHERE i.i_class_id = 5
  AND w.wr_returning_hdemo_sk = 2208
GROUP BY i.i_item_id, i.i_product_name
LIMIT 100
