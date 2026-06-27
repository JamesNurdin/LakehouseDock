-- Top 10 IP addresses by request count and their average line length
WITH ip_stats AS (
    SELECT
        split_part(line, ' ', 1) AS ip_address,
        length(line) AS line_len
    FROM web_logs
)
SELECT
    ip_address,
    count(*) AS request_count,
    avg(line_len) AS avg_line_length
FROM ip_stats
GROUP BY ip_address
ORDER BY request_count DESC
LIMIT 10
