WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS ts_str,
        regexp_extract(line, '"([^\"]+)"', 1) AS request,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status,
        regexp_extract(line, '\\s(\\d+|-)\\s*$', 1) AS size
    FROM web_logs
),
extracted AS (
    SELECT
        ip,
        date_parse(ts_str, '%d/%b/%Y:%H:%i:%s %z') AS ts,
        split(request, ' ')[1] AS method,
        split(request, ' ')[2] AS url,
        CAST(status AS integer) AS status_code,
        CASE WHEN size = '-' THEN 0 ELSE CAST(size AS integer) END AS size_bytes
    FROM parsed_logs
)
SELECT
    date_format(ts, '%Y-%m-%d %H:00:00') AS hour_bucket,
    status_code,
    COUNT(*) AS request_count,
    SUM(size_bytes) AS total_bytes,
    COUNT(DISTINCT ip) AS unique_visitors
FROM extracted
GROUP BY
    date_format(ts, '%Y-%m-%d %H:00:00'),
    status_code
ORDER BY
    hour_bucket,
    request_count DESC
