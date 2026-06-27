WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS log_timestamp,
        regexp_extract(line, '\\"([^ ]+) ([^ ]+) ([^\\"]+)\\"', 1) AS http_method,
        regexp_extract(line, '\\"([^ ]+) ([^ ]+) ([^\\"]+)\\"', 2) AS request_path,
        regexp_extract(line, '\\"([^ ]+) ([^ ]+) ([^\\"]+)\\"', 3) AS http_version,
        regexp_extract(line, '\\"\\s+(\\d{3})\\s+', 1) AS status_code,
        try_cast(regexp_extract(line, '\\"\\s+\\d{3}\\s+(\\d+)', 1) AS bigint) AS response_bytes,
        length(line) AS line_len
    FROM web_logs
),
agg_stats AS (
    SELECT
        http_method,
        status_code,
        COUNT(*) AS request_cnt,
        SUM(COALESCE(response_bytes, 0)) AS total_bytes,
        AVG(line_len) AS avg_line_len,
        MIN(log_timestamp) AS earliest_log,
        MAX(log_timestamp) AS latest_log
    FROM parsed_logs
    WHERE http_method IS NOT NULL
      AND status_code IS NOT NULL
    GROUP BY http_method, status_code
)
SELECT
    http_method,
    status_code,
    request_cnt,
    total_bytes,
    avg_line_len,
    earliest_log,
    latest_log,
    RANK() OVER (ORDER BY request_cnt DESC) AS request_rank
FROM agg_stats
ORDER BY request_cnt DESC
LIMIT 50
