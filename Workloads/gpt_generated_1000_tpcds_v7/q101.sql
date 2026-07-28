SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    cc_gmt_offset,
    cc_tax_percentage
FROM tpcds.call_center
WHERE cc_country = 'United States'
  AND cc_street_type = 'Avenue'
  AND cc_open_date_sk BETWEEN 2450800 AND 2450900
LIMIT 100
