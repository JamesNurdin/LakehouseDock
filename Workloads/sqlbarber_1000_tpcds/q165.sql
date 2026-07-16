SELECT date_dim.d_year,
       COUNT(store.s_store_sk) AS closed_store_cnt
FROM store
JOIN date_dim ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year = 1908
GROUP BY date_dim.d_year
