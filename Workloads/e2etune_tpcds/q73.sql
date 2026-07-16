SELECT t.t_hour,
       ca_ret.ca_location_type AS returning_location_type,
       ca_ref.ca_location_type AS refunded_location_type,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_refunded_cash) AS total_refunded_cash,
       COUNT(*) AS return_count
FROM web_returns wr
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer_address ca_ret
  ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
  ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE t.t_am_pm = 'PM'
  AND ca_ret.ca_gmt_offset = -5.00
  AND ca_ref.ca_gmt_offset = -6.00
GROUP BY t.t_hour, ca_ret.ca_location_type, ca_ref.ca_location_type
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 50
