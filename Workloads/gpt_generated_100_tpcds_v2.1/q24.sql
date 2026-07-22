SELECT DISTINCT s_store_name, s_city, s_state, s_gmt_offset
FROM tpcds.store
WHERE s_state = 'CA'
  AND s_rec_start_date >= DATE '1998-01-01'
ORDER BY s_city
LIMIT 100
