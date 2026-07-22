SELECT store.s_store_name,
       store.s_manager,
       date_dim.d_date,
       date_dim.d_fy_quarter_seq
FROM store
JOIN date_dim ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE date_dim.d_fy_quarter_seq = 15
  AND store.s_manager = 'Jose Valdez'
ORDER BY date_dim.d_date DESC
LIMIT 100
