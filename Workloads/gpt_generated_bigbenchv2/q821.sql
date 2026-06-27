WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\] "(\\w+) ([^ ]+) HTTP/[^\"]+" (\\d{3})', 1) AS http_method,
        regexp_extract(line, '\\] "(\\w+) ([^ ]+) HTTP/[^\"]+" (\\d{3})', 2) AS url,
        regexp_extract(line, '\\] "(\\w+) ([^ ]+) HTTP/[^\"]+" (\\d{3})', 3) AS status_code,
        length(line) AS line_length
    FROM web_logs
),
method_url_counts AS (
    SELECT
        http_method,
        url,
        status_code,
        count(*) AS request_count,
        avg(line_length) AS avg_line_len
    FROM parsed_logs
    WHERE http_method IS NOT NULL
      AND status_code = '200'
    GROUP BY http_method, url, status_code
),
ranked_urls AS (
    SELECT
        http_method,
        url,
        status_code,
        request_count,
        avg_line_len,
        row_number() OVER (PARTITION BY http_method ORDER BY request_count DESC) AS url_rank
    FROM method_url_counts
)
SELECT
    http_method,
    url,
    status_code,
    request_count,
    avg_line_len
FROM ranked_urls
WHERE url_rank <= 5
ORDER BY http_method, request_count DESC
