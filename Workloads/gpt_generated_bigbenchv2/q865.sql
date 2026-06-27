WITH parsed AS (
    SELECT
        line,
        regexp_extract(line, '"(\\S+)\\s', 1) AS http_method,
        regexp_extract(line, '"\\S+\\s(\\S+)\\s', 1) AS request_path,
        regexp_extract(line, '"\\S+\\s\\S+\\s\\S+"\\s+(\\d{3})', 1) AS status_code,
        length(line) AS line_length
    FROM web_logs
),
aggregated AS (
    SELECT
        http_method,
        request_path,
        status_code,
        count(*) AS request_count,
        avg(line_length) AS avg_line_length
    FROM parsed
    WHERE http_method IS NOT NULL
    GROUP BY http_method, request_path, status_code
)
SELECT
    http_method,
    request_path,
    status_code,
    request_count,
    avg_line_length,
    row_number() OVER (PARTITION BY http_method ORDER BY request_count DESC) AS rank_within_method
FROM aggregated
WHERE request_count > 0
ORDER BY http_method, rank_within_method
LIMIT 100
