SELECT DISTINCT c.c_first_name, c.c_last_name, w.wr_return_quantity, w.wr_net_loss
FROM tpcds.customer c
JOIN tpcds.web_returns w
  ON w.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_first_name = 'Betty'
  AND w.wr_return_quantity >= 15
ORDER BY w.wr_net_loss DESC
LIMIT 100
