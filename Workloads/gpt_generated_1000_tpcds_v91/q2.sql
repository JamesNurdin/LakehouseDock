SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    cc_gmt_offset,
    cc_tax_percentage
FROM tpcds.call_center
WHERE cc_hours = '8AM-4PM'
  AND cc_state = 'CA'
ORDER BY cc_gmt_offset DESC, cc_tax_percentage ASC
LIMIT 100
