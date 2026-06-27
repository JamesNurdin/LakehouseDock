WITH parsed_logs AS (
    SELECT
        split(line, ' ')[1] AS ip_address,
        regexp_extract(line, '"(\S+) (\S+) (\S+)"', 1) AS request_method,
        regexp_extract(line, '"(\S+) (\S+) (\S+)"', 2) AS request_path,
        split(line, ' ')[9] AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
),
method_path_counts AS (
    SELECT
        request_method,
        request_path,
        status_code,
        count(*) AS request_count,
        avg(line_length) AS avg_line_length
    FROM parsed_logs
    GROUP BY request_method, request_path, status_code
)
SELECT
    request_method,
    request_path,
    status_code,
    request_count,
    avg_line_length,
    rank() OVER (PARTITION BY request_method ORDER BY request_count DESC) AS method_path_rank
FROM method_path_counts
WHERE request_count > 10
ORDER BY request_method, method_path_rank
LIMIT 50
