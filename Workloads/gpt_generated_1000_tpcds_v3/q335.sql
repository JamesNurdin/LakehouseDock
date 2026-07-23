SELECT w_state,
       COUNT(DISTINCT w_city) AS distinct_city_cnt,
       COUNT(*) AS total_warehouses
FROM warehouse
WHERE w_country = 'United States'
  AND w_street_type = 'Avenue'
GROUP BY w_state
HAVING COUNT(*) > 1
ORDER BY distinct_city_cnt DESC, w_state
