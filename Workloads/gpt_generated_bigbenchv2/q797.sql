WITH parsed_logs AS (
    SELECT
        line,
        date_parse(
            regexp_extract(line, '\\[(.*?)\\]', 1),
            '%d/%b/%Y:%H:%i:%s %z'
        ) AS log_ts,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        CAST(regexp_extract(line, '" (\\d{3}) ', 1) AS INTEGER) AS status_code
    FROM web_logs
    WHERE regexp_extract(line, '\\[(.*?)\\]', 1) IS NOT NULL
)
SELECT
    date_trunc('day', log_ts) AS log_date,
    count(*) AS total_requests,
    approx_distinct(ip_address) AS unique_ips,
    sum(CASE WHEN status_code = 200 THEN 1 ELSE 0 END) AS successful_requests,
    sum(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) AS error_requests
FROM parsed_logs
GROUP BY date_trunc('day', log_ts)
ORDER BY log_date
