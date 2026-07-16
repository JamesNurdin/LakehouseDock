SELECT
  d_ret.d_year AS return_year,
  d_ret.d_quarter_name AS return_quarter,
  i.i_category AS item_category,
  i.i_brand AS item_brand,
  s.s_state AS store_state,
  s.s_market_desc AS market_description,
  COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
  COUNT(DISTINCT wr.wr_order_number) AS web_return_txns,
  SUM(sr.sr_return_amt) AS total_store_return_amt,
  SUM(wr.wr_return_amt) AS total_web_return_amt,
  SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_combined_net_loss,
  AVG(sr.sr_return_quantity) AS avg_store_return_qty,
  AVG(wr.wr_return_quantity) AS avg_web_return_qty,
  SUM(CASE WHEN sr.sr_return_amt > 200 THEN sr.sr_return_amt ELSE 0 END) AS high_value_store_returns,
  SUM(CASE WHEN wr.wr_return_amt > 200 THEN wr.wr_return_amt ELSE 0 END) AS high_value_web_returns,
  AVG(date_diff('day', d_closed.d_date, d_ret.d_date)) AS avg_days_between_closed_and_return,
  SUM(CASE WHEN d_closed.d_date < d_ret.d_date THEN 1 ELSE 0 END) AS returns_after_store_closed,
  SUM(sr.sr_return_amt) / NULLIF(SUM(wr.wr_return_amt), 0) AS store_to_web_return_ratio
FROM date_dim d_ret
JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
                     AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_closed.d_date IS NOT NULL
GROUP BY
  d_ret.d_year,
  d_ret.d_quarter_name,
  i.i_category,
  i.i_brand,
  s.s_state,
  s.s_market_desc
HAVING SUM(sr.sr_return_amt) > 1000 OR SUM(wr.wr_return_amt) > 1000
ORDER BY total_combined_net_loss DESC
LIMIT 100
