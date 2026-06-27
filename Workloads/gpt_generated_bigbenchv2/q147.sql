/*
  Analytical query on the web_logs table.
  It parses each log line to extract the HTTP method and request path,
  aggregates request counts and average line length per method‑path pair,
  and then ranks the most frequent paths within each HTTP method.
*/
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"([^ ]+)', 1) AS http_method,
        regexp_extract(line, '"[^ ]+ ([^ ]+)', 1) AS request_path,
        length(line) AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
),
method_path_counts AS (
    SELECT
        http_method,
        request_path,
        COUNT(*) AS request_count,
        AVG(line_length) AS avg_line_length
    FROM parsed_logs
    GROUP BY http_method, request_path
)
SELECT
    http_method,
    request_path,
    request_count,
    avg_line_length,
    ROW_NUMBER() OVER (PARTITION BY http_method ORDER BY request_count DESC) AS rank_by_method
FROM method_path_counts
WHERE request_count > 10
ORDER BY http_method, rank_by_method
LIMIT 50
