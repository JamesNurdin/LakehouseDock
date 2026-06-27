WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
  FROM iceberg.bigbenchv2_sf1.web_logs
)
SELECT
  day_of_month(wl_timestamp) AS d,
  month(wl_timestamp)       AS m,
  year(wl_timestamp)        AS y,
  COUNT(*)                  AS PageViews
FROM logs
GROUP BY wl_timestamp
ORDER BY PageViews DESC
LIMIT 10
