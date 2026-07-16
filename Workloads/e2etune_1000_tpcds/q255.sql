SELECT ws.web_site_id AS site_id,
       ws.web_market_manager AS market_manager,
       d.d_quarter_name AS quarter,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_net_loss) AS total_net_loss,
       AVG(wr.wr_return_quantity) AS avg_return_qty,
       SUM(wr.wr_fee) AS total_fee,
       COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
WHERE d.d_weekend = 'Y'
  AND d.d_quarter_seq = 2
  AND ws.web_state = 'CA'
GROUP BY ws.web_site_id, ws.web_market_manager, d.d_quarter_name
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100
