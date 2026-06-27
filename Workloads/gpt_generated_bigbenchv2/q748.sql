WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([A-Z]+) ', 1) AS method,
        regexp_extract(line, '\\s(\\d{3})\\s', 1) AS status_code,
        length(line) AS line_len
    FROM web_logs
),
status_counts AS (
    SELECT
        method,
        status_code,
        count(*) AS cnt,
        avg(line_len) AS avg_len
    FROM parsed_logs
    WHERE method IS NOT NULL
      AND status_code IS NOT NULL
    GROUP BY method, status_code
)
SELECT
    method,
    status_code,
    cnt,
    avg_len,
    rank() OVER (PARTITION BY method ORDER BY cnt DESC) AS status_rank
FROM status_counts
ORDER BY method, status_rank
LIMIT 100
