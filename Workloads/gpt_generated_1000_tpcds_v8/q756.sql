SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    cc_gmt_offset
FROM tpcds.call_center
WHERE cc_state = 'CA'
  AND cc_gmt_offset BETWEEN -8.00 AND -5.00
ORDER BY cc_city ASC
