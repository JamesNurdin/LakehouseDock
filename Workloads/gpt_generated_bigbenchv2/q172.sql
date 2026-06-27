WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^\\]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 1) AS request_method,
        regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 2) AS request_path,
        regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 3) AS request_protocol,
        regexp_extract(line, '"[^"]+"\\s+(\\d{3})\\s+(\\d+|-)', 1) AS status_code,
        regexp_extract(line, '"[^"]+"\\s+(\\d{3})\\s+(\\d+|-)', 2) AS response_bytes
    FROM web_logs
    WHERE regexp_extract(line, '"([^ ]+) ([^ ]+) ([^"]+)"', 1) IS NOT NULL
),
aggregated AS (
    SELECT
        request_method,
        request_path,
        COUNT(*) AS request_cnt,
        COUNT(DISTINCT ip) AS unique_ip_cnt,
        SUM(CASE WHEN response_bytes = '-' THEN 0 ELSE CAST(response_bytes AS BIGINT) END) AS total_bytes
    FROM parsed_logs
    GROUP BY request_method, request_path
),
ranked_paths AS (
    SELECT
        request_method,
        request_path,
        request_cnt,
        unique_ip_cnt,
        total_bytes,
        ROW_NUMBER() OVER (PARTITION BY request_method ORDER BY request_cnt DESC) AS rn
    FROM aggregated
)
SELECT
    request_method,
    request_path,
    request_cnt,
    unique_ip_cnt,
    total_bytes
FROM ranked_paths
WHERE rn <= 10
ORDER BY request_method, request_cnt DESC
