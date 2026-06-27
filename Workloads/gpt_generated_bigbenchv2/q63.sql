/*
  Analytical query on the web_logs table.
  - Parses the timestamp, HTTP method, status code, and response size from each log line.
  - Aggregates request counts, average/total/median bytes per day, method, and status.
  - Ranks methods by request volume for each day.
*/
WITH parsed_logs AS (
    SELECT
        line,
        CAST(
            date_parse(
                regexp_extract(line, '\\[(.*?)\\]', 1),
                '%d/%b/%Y:%H:%i:%s %z'
            ) AS date
        ) AS log_date,
        regexp_extract(line, '\\"(\\S+)\\s+\\S+\\s+\\S+\\"', 1) AS method,
        CAST(regexp_extract(line, '\\"\\S+\\s+\\S+\\s+\\S+\\"\\s+(\\d{3})\\s+', 1) AS integer) AS status,
        CAST(regexp_extract(line, '\\"\\S+\\s+\\S+\\s+\\S+\\"\\s+\\d{3}\\s+(\\d+)', 1) AS integer) AS bytes
    FROM web_logs
    WHERE regexp_extract(line, '\\[(.*?)\\]', 1) IS NOT NULL
),
agg AS (
    SELECT
        log_date,
        method,
        status,
        COUNT(*) AS request_count,
        AVG(bytes) AS avg_bytes,
        SUM(bytes) AS total_bytes,
        approx_percentile(bytes, 0.5) AS median_bytes
    FROM parsed_logs
    WHERE method IS NOT NULL AND status IS NOT NULL
    GROUP BY log_date, method, status
)
SELECT
    log_date,
    method,
    status,
    request_count,
    avg_bytes,
    total_bytes,
    median_bytes,
    RANK() OVER (PARTITION BY log_date ORDER BY request_count DESC) AS request_rank_by_day
FROM agg
ORDER BY log_date DESC, request_rank_by_day
LIMIT 100
