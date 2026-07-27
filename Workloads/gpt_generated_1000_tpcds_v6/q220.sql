WITH high_value_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_net_profit > 1000
)
SELECT
    c.c_customer_id AS customer_id,
    ca.ca_state AS state,
    td.t_time_id AS time_id,
    sr.sr_return_amt AS return_amt,
    sr.sr_return_tax AS return_tax,
    sr.sr_net_loss AS net_loss
FROM store_returns sr
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE td.t_am_pm = 'PM'
  AND sr.sr_return_amt > 50
  AND EXISTS (SELECT 1 FROM high_value_customers h WHERE h.c_customer_sk = c.c_customer_sk)
UNION ALL
SELECT
    c.c_customer_id AS customer_id,
    ca.ca_state AS state,
    td.t_time_id AS time_id,
    wr.wr_return_amt AS return_amt,
    wr.wr_return_tax AS return_tax,
    wr.wr_net_loss AS net_loss
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE td.t_am_pm = 'PM'
  AND wr.wr_return_amt > 50
  AND EXISTS (SELECT 1 FROM high_value_customers h WHERE h.c_customer_sk = c.c_customer_sk)
ORDER BY net_loss DESC, customer_id
LIMIT 100
