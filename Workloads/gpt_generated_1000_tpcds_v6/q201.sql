SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    cc_sq_ft,
    cc_gmt_offset
FROM tpcds.call_center
WHERE cc_state = 'CA'
  AND cc_gmt_offset = -8.00
  AND cc_sq_ft > 1000000
LIMIT 100
