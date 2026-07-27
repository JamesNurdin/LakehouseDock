SELECT DISTINCT s.s_store_name,
                s.s_city,
                sr.sr_return_quantity
FROM store AS s
JOIN store_returns AS sr ON sr.sr_store_sk = s.s_store_sk
WHERE s.s_rec_end_date = DATE '2000-03-12'
  AND sr.sr_return_quantity > 20
LIMIT 100
