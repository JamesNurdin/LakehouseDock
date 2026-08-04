SELECT
    ca.ca_address_id,
    ca.ca_city,
    SUM(wr.wr_net_loss) AS total_loss
FROM web_returns wr
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'WA'
  AND wr.wr_net_loss > 500
GROUP BY ca.ca_address_id, ca.ca_city
ORDER BY total_loss DESC
LIMIT 10
