SELECT ca.ca_county,
       SUM(wr.wr_refunded_cash) AS total_refunded_cash,
       COUNT(*) AS return_count
FROM web_returns wr
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE wr.wr_return_amt_inc_tax > 1000
  AND ca.ca_gmt_offset = -7.00
GROUP BY ca.ca_county
ORDER BY total_refunded_cash DESC
LIMIT 10
