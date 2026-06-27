WITH parsed AS (
    SELECT
        line,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}):([0-9]{2}):[0-9]{2}:[0-9]{2} [^\\]]+\\]', 1) AS log_date,
        regexp_extract(line, '\\[(\\d{2}/[A-Za-z]{3}/\\d{4}):([0-9]{2}):[0-9]{2}:[0-9]{2} [^\\]]+\\]', 2) AS log_hour,
        regexp_extract(line, '\\"[A-Z]+ ([^\\"]+) HTTP/[0-9.]+' , 1) AS request_path,
        regexp_extract(line, '\\"\\s+(\\d{3})\\s', 1) AS status_code
    FROM web_logs
    WHERE line IS NOT NULL
),
path_counts AS (
    SELECT
        log_date,
        log_hour,
        request_path,
        count(*) AS path_requests,
        count_if(status_code = '200') AS success_requests,
        count_if(status_code = '404') AS not_found_requests
    FROM parsed
    GROUP BY log_date, log_hour, request_path
),
ranked_paths AS (
    SELECT
        log_date,
        log_hour,
        request_path,
        path_requests,
        success_requests,
        not_found_requests,
        row_number() OVER (PARTITION BY log_date, log_hour ORDER BY path_requests DESC) AS rn
    FROM path_counts
)
SELECT
    log_date,
    log_hour,
    request_path,
    path_requests,
    success_requests,
    not_found_requests
FROM ranked_paths
WHERE rn <= 3
ORDER BY log_date, log_hour, path_requests DESC
