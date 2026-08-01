SELECT ws.web_state,
       COUNT(DISTINCT ws.web_city) AS distinct_city_count
FROM web_site ws
WHERE ws.web_city IN ('Mount Olive', 'Woodlawn')
  AND ws.web_rec_start_date >= DATE '2000-01-01'
GROUP BY ws.web_state
ORDER BY distinct_city_count DESC
LIMIT 100
