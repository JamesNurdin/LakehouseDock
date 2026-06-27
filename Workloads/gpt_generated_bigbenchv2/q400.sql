WITH parsed_logs AS (
    SELECT line,
           split_part(line, ' ', 1) AS ip_address,
           split_part(line, ' ', 6) AS request_method,
           split_part(line, ' ', 7) AS request_path,
           length(line) AS line_len
    FROM web_logs
),
aggregated AS (
    SELECT request_method,
           request_path,
           count(*) AS request_count,
           avg(line_len) AS avg_line_len,
           sum(line_len) AS total_line_len
    FROM parsed_logs
    WHERE request_method IS NOT NULL AND request_method <> ''
    GROUP BY request_method, request_path
)
SELECT request_method,
       request_path,
       request_count,
       avg_line_len,
       total_line_len,
       row_number() OVER (ORDER BY request_count DESC) AS rank_by_requests
FROM aggregated
ORDER BY request_count DESC
LIMIT 10
