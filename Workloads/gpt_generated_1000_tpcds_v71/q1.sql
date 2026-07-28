SELECT
    cc_call_center_id,
    cc_name,
    cc_city,
    cc_state,
    cc_employees,
    cc_gmt_offset
FROM tpcds.call_center
WHERE cc_city IN ('Salem', 'Greenwood')
  AND cc_mkt_id = 3
ORDER BY cc_state ASC, cc_name ASC
LIMIT 100
