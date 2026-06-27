WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '\\"(GET|POST|PUT|DELETE|HEAD|OPTIONS)\\s', 1) AS method,
        CAST(regexp_extract(line, '\\"\\s(\\d{3})\\s', 1) AS integer) AS status_code,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status_code,
    COUNT(*) AS request_cnt,
    AVG(line_len) AS avg_line_len,
    MIN(line_len) AS min_line_len,
    MAX(line_len) AS max_line_len
FROM parsed_logs
WHERE method IS NOT NULL AND status_code IS NOT NULL
GROUP BY method, status_code
ORDER BY request_cnt DESC
LIMIT 20
