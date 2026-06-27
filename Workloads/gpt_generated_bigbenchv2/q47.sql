WITH parsed_logs AS (
    SELECT
        TRY_CAST(split_part(line, ' ', 1) AS TIMESTAMP) AS log_timestamp,
        DATE_TRUNC('hour', TRY_CAST(split_part(line, ' ', 1) AS TIMESTAMP)) AS hour_bucket,
        split_part(line, ' ', 2) AS ip_address,
        split_part(line, ' ', 3) AS request_method,
        split_part(line, ' ', 4) AS request_path,
        split_part(line, ' ', 5) AS status_code,
        TRY_CAST(split_part(line, ' ', 6) AS BIGINT) AS response_bytes
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    request_method,
    CAST(hour_bucket AS VARCHAR) AS hour_bucket_str,
    COUNT(*) AS request_count,
    SUM(response_bytes) AS total_bytes
FROM parsed_logs
WHERE log_timestamp IS NOT NULL
GROUP BY request_method, hour_bucket
ORDER BY request_count DESC
LIMIT 20
