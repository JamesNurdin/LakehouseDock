/*
  Analytical query on the web_logs table.
  It parses each log line, extracts the timestamp, derives a request date,
  counts the number of requests per date, and shows each day's share of the total traffic.
*/
WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        regexp_extract(line, '\\[([^]]+)\\]', 1) AS timestamp_str,
        regexp_extract(line, '"([^ ]+)', 1) AS method,
        regexp_extract(line, '"[^ ]+ ([^ ]+)', 1) AS url,
        regexp_extract(line, '"[^ ]+ [^ ]+ ([^ ]+)', 1) AS protocol,
        regexp_extract(line, '" ([0-9]{3}) ', 1) AS status_code,
        regexp_extract(line, ' ([0-9]+)$', 1) AS size_str
    FROM web_logs
),

daily_requests AS (
    SELECT
        split(timestamp_str, ':')[1] AS request_date,
        COUNT(*) AS request_cnt
    FROM parsed_logs
    WHERE timestamp_str IS NOT NULL
    GROUP BY split(timestamp_str, ':')[1]
)
SELECT
    request_date,
    request_cnt,
    ROUND(100.0 * request_cnt / SUM(request_cnt) OVER (), 2) AS pct_of_total_requests
FROM daily_requests
ORDER BY request_date
