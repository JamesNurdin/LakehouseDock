SELECT s.s_store_name,
       s.s_city,
       s.s_zip,
       s.s_floor_space,
       d.d_date
FROM store s
JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_moy = 6
  AND d.d_following_holiday = 'N'
  AND s.s_floor_space > 8000000
LIMIT 100
