SELECT cc_state,
       cc_gmt_offset,
       COUNT(*) AS num_call_centers
FROM tpcds.call_center
WHERE cc_state IN ('NY', 'FL')
  AND cc_gmt_offset = -5.00
GROUP BY cc_state, cc_gmt_offset
ORDER BY num_call_centers DESC
LIMIT 100
