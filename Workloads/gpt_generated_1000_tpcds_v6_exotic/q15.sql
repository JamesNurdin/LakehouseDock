SELECT w_state,
       COUNT(*) AS warehouse_cnt
FROM tpcds.warehouse
WHERE w_gmt_offset = -6.00
  AND w_state = 'CA'
GROUP BY w_state
