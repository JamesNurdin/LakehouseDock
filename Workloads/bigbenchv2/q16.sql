WITH logs AS (
  SELECT
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name
  FROM iceberg.bigbenchv2_sf1.web_logs
)
SELECT
  wl_webpage_name,
  COUNT(*) AS cnt
FROM logs
WHERE wl_webpage_name IS NOT NULL
GROUP BY wl_webpage_name
ORDER BY cnt DESC
LIMIT 10
