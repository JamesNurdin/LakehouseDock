SELECT s.s_store_id, s.s_city, sr.sr_ticket_number, sr.sr_return_amt_inc_tax
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_county = 'Jackson County'
  AND sr.sr_return_amt_inc_tax > 1000
LIMIT 100
