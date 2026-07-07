WITH customer_summary AS (
  SELECT
    wl_customer_id,
    COUNT(*) AS visits,
    MIN(wl_timestamp) AS first_visit,
    MAX(wl_timestamp) AS last_visit
  FROM web_logs
  GROUP BY wl_customer_id
)
SELECT
  wl.wl_customer_id,
  wl.wl_webpage_name,
  cs.visits,
  cs.first_visit,
  cs.last_visit
FROM web_logs wl
JOIN customer_summary cs
  ON wl.wl_customer_id = cs.wl_customer_id
WHERE wl.wl_key1 > 0
ORDER BY cs.visits DESC
LIMIT 20
