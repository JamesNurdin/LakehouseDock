WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"([^ ]+)', 1) AS method,
        regexp_extract(line, '"[^ ]+ ([^ ]+)', 1) AS url,
        TRY_CAST(regexp_extract(line, '"\s([0-9]{3})\s', 1) AS INTEGER) AS status_code
    FROM web_logs
    WHERE line IS NOT NULL
),
method_stats AS (
    SELECT
        method,
        COUNT(*) AS request_count,
        approx_distinct(url) AS unique_url_count,
        SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS server_error_count
    FROM parsed_logs
    WHERE method IS NOT NULL
    GROUP BY method
)
SELECT
    method,
    request_count,
    unique_url_count,
    server_error_count,
    RANK() OVER (ORDER BY request_count DESC) AS method_rank
FROM method_stats
ORDER BY request_count DESC
LIMIT 10
