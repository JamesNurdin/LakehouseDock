WITH store_item_returns AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_refunded_cash) AS avg_refunded_cash,
    MAX(sr.sr_return_amt) AS max_return_amt,
    MIN(sr.sr_return_amt) AS min_return_amt
  FROM store_returns sr
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  WHERE s.s_country = 'United States'
    AND i.i_size IN ('medium', 'small')
    AND sr.sr_refunded_cash > 50
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY s.s_store_id, s.s_store_name, i.i_item_id, i.i_product_name, r.r_reason_desc
)

SELECT
  s_store_id,
  s_store_name,
  i_item_id,
  i_product_name,
  r_reason_desc,
  total_return_amt,
  total_return_qty,
  return_cnt,
  avg_refunded_cash,
  max_return_amt,
  min_return_amt,
  ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amt DESC) AS rn_store_item,
  RANK() OVER (ORDER BY total_return_amt DESC) AS overall_rank
FROM store_item_returns
ORDER BY total_return_amt DESC, s_store_id
LIMIT 100
