WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
    FROM iceberg.bigbenchv2_sf1.web_logs
)

SELECT
    day(CAST(wl_timestamp AS date)) AS d,
    month(CAST(wl_timestamp AS date)) AS m,
    year(CAST(wl_timestamp AS date)) AS y,
    COUNT(DISTINCT wl_customer_id) AS UniqueVisitors
FROM logs
WHERE wl_customer_id IS NOT NULL
  AND wl_timestamp IS NOT NULL
GROUP BY
    wl_timestamp
ORDER BY UniqueVisitors DESC
LIMIT 10