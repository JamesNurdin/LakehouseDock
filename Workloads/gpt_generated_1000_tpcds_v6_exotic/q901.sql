SELECT
  s_store_id,
  s_store_name,
  s_city,
  s_state,
  s_number_employees
FROM tpcds.store
WHERE s_rec_end_date = DATE '2001-03-12'
  AND s_market_manager = 'Dustin Kelly'
ORDER BY s_store_id
