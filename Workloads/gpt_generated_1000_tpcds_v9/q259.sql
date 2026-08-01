SELECT s_store_id,
       s_store_name,
       s_city,
       s_state,
       s_floor_space,
       s_number_employees,
       s_gmt_offset
FROM tpcds.store
WHERE s_country = 'United States'
  AND s_street_number = '84'
LIMIT 100
