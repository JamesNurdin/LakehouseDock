SELECT s_store_id,
       s_store_name,
       s_city,
       s_state,
       s_number_employees,
       s_floor_space,
       s_tax_percentage
FROM tpcds.store
WHERE s_state = 'CA'
  AND s_number_employees > 100
ORDER BY s_number_employees DESC,
         s_store_name
LIMIT 100
