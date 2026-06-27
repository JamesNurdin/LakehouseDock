WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '"([A-Z]+)\\s', 1) AS method,
        regexp_extract(line, '"[A-Z]+\\s([^\\s]+)', 1) AS endpoint,
        length(line) AS line_len
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    endpoint,
    request_cnt,
    avg_line_len,
    rank() OVER (PARTITION BY method ORDER BY request_cnt DESC) AS endpoint_rank
FROM (
    SELECT
        method,
        endpoint,
        count(*) AS request_cnt,
        avg(line_len) AS avg_line_len
    FROM parsed_logs
    WHERE method IS NOT NULL
    GROUP BY method, endpoint
) AS agg
ORDER BY request_cnt DESC
LIMIT 20
