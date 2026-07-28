SELECT s_state,
       COUNT(*) AS store_count,
       AVG(s_floor_space) AS avg_floor_space
FROM tpcds.store
WHERE s_country = 'United States'
  AND s_city = 'Spring Valley'
GROUP BY s_state
ORDER BY store_count DESC
