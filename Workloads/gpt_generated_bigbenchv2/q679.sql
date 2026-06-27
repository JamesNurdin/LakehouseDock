WITH parsed AS (
    SELECT
        regexp_extract(line, '\\[([^:]+)', 1) AS request_date,
        regexp_extract(line, '"([A-Z]+)', 1) AS http_method,
        CAST(regexp_extract(line, '\\"\\s+(\\d{3})\\s', 1) AS integer) AS status_code,
        length(line) AS line_length
    FROM web_logs
    WHERE regexp_extract(line, '\\[([^:]+)', 1) IS NOT NULL
      AND regexp_extract(line, '"([A-Z]+)', 1) IS NOT NULL
      AND regexp_extract(line, '\\"\\s+(\\d{3})\\s', 1) IS NOT NULL
), agg AS (
    SELECT
        request_date,
        http_method,
        status_code,
        COUNT(*) AS request_cnt,
        AVG(line_length) AS avg_line_len
    FROM parsed
    GROUP BY request_date, http_method, status_code
)
SELECT
    request_date,
    http_method,
    status_code,
    request_cnt,
    avg_line_len,
    ROUND(100.0 * request_cnt / SUM(request_cnt) OVER (PARTITION BY request_date), 2) AS pct_of_day
FROM agg
ORDER BY request_cnt DESC
LIMIT 50
