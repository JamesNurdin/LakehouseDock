SELECT
    s_state,
    COUNT(*) AS store_count,
    AVG(s_number_employees) AS avg_employees
FROM tpcds.store
WHERE s_number_employees > 250
  AND s_tax_percentage <= 0.05
GROUP BY s_state
HAVING COUNT(*) >= 2
ORDER BY store_count DESC
