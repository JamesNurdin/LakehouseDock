SELECT s.s_store_name,
       s.s_city,
       d.d_date
FROM store s
JOIN date_dim d
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
ORDER BY d.d_date DESC
LIMIT 10
