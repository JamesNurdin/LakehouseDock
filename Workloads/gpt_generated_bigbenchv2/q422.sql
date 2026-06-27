WITH status_counts AS (
    SELECT
        cast(regexp_extract(line, '\\s(\\d{3})\\s', 1) AS integer) AS status_code,
        count(*) AS request_count
    FROM web_logs
    WHERE regexp_extract(line, '\\s(\\d{3})\\s', 1) <> ''
    GROUP BY cast(regexp_extract(line, '\\s(\\d{3})\\s', 1) AS integer)
)
SELECT
    status_code,
    request_count,
    round(100.0 * request_count / sum(request_count) OVER (), 2) AS pct_of_total
FROM status_counts
ORDER BY request_count DESC
LIMIT 10
