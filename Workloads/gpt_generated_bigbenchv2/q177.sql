WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '"([A-Z]+)\\s', 1)        AS method,
        regexp_extract(line, '"[A-Z]+\\s([^\\s]+)', 1) AS path,
        regexp_extract(line, '"\\s(\\d{3})\\s', 1)   AS status,
        length(line)                                    AS line_length
    FROM web_logs
    WHERE line IS NOT NULL
)
SELECT
    method,
    status,
    request_count,
    avg_line_length,
    median_line_length,
    avg_path_length,
    min_line_length,
    max_line_length,
    RANK() OVER (PARTITION BY method ORDER BY request_count DESC) AS status_rank_by_method
FROM (
    SELECT
        method,
        status,
        COUNT(*)                                 AS request_count,
        AVG(line_length)                         AS avg_line_length,
        approx_percentile(line_length, 0.5)      AS median_line_length,
        AVG(length(path))                        AS avg_path_length,
        MIN(line_length)                         AS min_line_length,
        MAX(line_length)                         AS max_line_length
    FROM parsed_logs
    WHERE method IS NOT NULL
      AND status IS NOT NULL
    GROUP BY method, status
) agg
ORDER BY request_count DESC
LIMIT 10
