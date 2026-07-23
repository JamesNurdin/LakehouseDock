SELECT
  ca.ca_city,
  ca.ca_state,
  SUM(ss.ss_net_paid) AS total_net_paid,
  COUNT(*) AS transaction_count
FROM store_sales AS ss
JOIN customer_address AS ca
  ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_zip = '49843'
  AND ss.ss_hdemo_sk = 1458
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_net_paid DESC
