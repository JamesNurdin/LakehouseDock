SELECT ca.ca_state,
       SUM(sr.sr_net_loss) AS total_store_loss,
       SUM(wr.wr_net_loss) AS total_web_loss
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'HI'
GROUP BY ca.ca_state
