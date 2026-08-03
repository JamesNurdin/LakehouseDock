SELECT s.s_state,
       COUNT(*) AS store_count,
       AVG(s.s_floor_space) AS avg_floor_space
FROM tpcds.store AS s
WHERE s.s_manager = 'Joe Johnson'
  AND s.s_state = 'CA'
GROUP BY s.s_state
ORDER BY store_count DESC
