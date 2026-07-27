SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    s_gmt_offset
FROM tpcds.store
WHERE s_state = 'CA'
  AND s_gmt_offset = -8.00
  AND s_number_employees > 50
ORDER BY s_store_name ASC
LIMIT 100
