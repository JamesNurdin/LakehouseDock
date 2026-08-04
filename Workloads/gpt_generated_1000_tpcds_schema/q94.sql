SELECT
    s_store_name,
    s_city,
    s_state,
    s_number_employees,
    s_floor_space
FROM tpcds.store
WHERE s_county = 'Levy County'
  AND s_zip = '15709'
