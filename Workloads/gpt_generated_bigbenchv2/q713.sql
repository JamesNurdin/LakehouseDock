WITH method_counts AS (
    SELECT regexp_extract(line, '"([A-Z]+) ', 1) AS method,
           count(*) AS method_count
    FROM web_logs
    WHERE regexp_extract(line, '"([A-Z]+) ', 1) IS NOT NULL
    GROUP BY regexp_extract(line, '"([A-Z]+) ', 1)
)
SELECT method,
       method_count,
       method_count * 100.0 / total_requests AS pct_of_total
FROM (
    SELECT method,
           method_count,
           sum(method_count) OVER () AS total_requests
    FROM method_counts
) t
ORDER BY method_count DESC
LIMIT 5
