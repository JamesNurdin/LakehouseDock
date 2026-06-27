SELECT
  wl_webpage_name,
  COUNT(*) AS cnt
FROM (
  SELECT
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
  FROM iceberg.bigbenchv2_sf1.web_logs
) AS logs
WHERE wl_webpage_name IS NOT NULL
  AND CAST(wl_timestamp AS date) >= DATE '2013-02-14'
  AND CAST(wl_timestamp AS date) < DATE '2014-02-15'
GROUP BY wl_webpage_name
ORDER BY cnt DESC
LIMIT 10