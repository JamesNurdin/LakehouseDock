SELECT s_store_id, s_store_name, s_city, s_state, s_floor_space, s_number_employees
FROM tpcds.store
WHERE s_state = 'CA'
  AND s_floor_space >= 2000
ORDER BY s_floor_space DESC, s_store_name
LIMIT 100
