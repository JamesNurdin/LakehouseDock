SELECT ca.ca_state, SUM(sr.sr_return_amt) AS total_return_amount FROM store_returns sr JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk WHERE ca.ca_state = 'IL' GROUP BY ca.ca_state
