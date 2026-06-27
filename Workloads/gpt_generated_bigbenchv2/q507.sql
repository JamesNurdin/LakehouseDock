WITH parsed AS (
    SELECT
        line,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}):(\\d{2}):\\d{2}:\\d{2}', 1) AS date_str,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}):(\\d{2}):\\d{2}:\\d{2}', 2) AS hour,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code
    FROM web_logs
    WHERE line IS NOT NULL
),
aggregated AS (
    SELECT
        date_str,
        hour,
        status_code,
        COUNT(*) AS request_count
    FROM parsed
    WHERE date_str IS NOT NULL
      AND hour IS NOT NULL
      AND status_code IS NOT NULL
    GROUP BY date_str, hour, status_code
)
SELECT
    date_str,
    hour,
    status_code,
    request_count,
    ROUND(100.0 * request_count / SUM(request_count) OVER (PARTITION BY date_str), 2) AS pct_of_day
FROM aggregated
ORDER BY date_str, hour, request_count DESC
LIMIT 50
