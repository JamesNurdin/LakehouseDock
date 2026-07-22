SELECT ca.ca_city,
       SUM(sr.sr_net_loss) AS total_net_loss
FROM store_returns sr
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND sr.sr_net_loss > 100
GROUP BY ca.ca_city
ORDER BY total_net_loss DESC
LIMIT 100
