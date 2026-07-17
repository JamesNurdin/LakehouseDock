SELECT
  d.d_date AS return_date,
  i.i_item_id AS item_id,
  i.i_product_name AS product_name,
  sr.sr_return_quantity AS return_quantity,
  sr.sr_return_amt AS return_amount,
  r.r_reason_desc AS reason_desc,
  CAST('store' AS VARCHAR) AS channel
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'

UNION ALL

SELECT
  d.d_date AS return_date,
  i.i_item_id AS item_id,
  i.i_product_name AS product_name,
  wr.wr_return_quantity AS return_quantity,
  wr.wr_return_amt AS return_amount,
  r.r_reason_desc AS reason_desc,
  CAST('web' AS VARCHAR) AS channel
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
ORDER BY return_date, channel
