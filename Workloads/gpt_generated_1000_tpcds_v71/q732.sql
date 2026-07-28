SELECT ca.ca_city,
       ca.ca_state,
       SUM(wr.wr_refunded_cash) AS total_refunded_cash
FROM tpcds.web_returns wr
JOIN tpcds.customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND wr.wr_refunded_cash > 100
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_refunded_cash DESC
