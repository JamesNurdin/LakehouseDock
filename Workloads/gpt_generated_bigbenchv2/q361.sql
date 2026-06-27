WITH parsed_logs AS (
    SELECT
        regexp_extract(line, '^([^ ]+)', 1) AS ip_address,
        regexp_extract(line, '\\"(\\w+)\\s', 1) AS http_method,
        regexp_extract(line, '\\"\\w+\\s([^\\s]+)', 1) AS url_path,
        regexp_extract(line, '\\"\\s(\\d{3})\\s', 1) AS status_code,
        regexp_extract(line, '\\"\\s\\d{3}\\s(\\d+)', 1) AS response_bytes
    FROM web_logs
),
url_agg AS (
    SELECT
        http_method,
        url_path,
        status_code,
        COUNT(*) AS request_cnt,
        SUM(CAST(response_bytes AS BIGINT)) AS total_bytes
    FROM parsed_logs
    WHERE http_method IS NOT NULL
    GROUP BY http_method, url_path, status_code
),
ranked_urls AS (
    SELECT
        http_method,
        url_path,
        status_code,
        request_cnt,
        total_bytes,
        ROW_NUMBER() OVER (PARTITION BY http_method ORDER BY request_cnt DESC) AS rn
    FROM url_agg
)
SELECT
    http_method,
    url_path,
    status_code,
    request_cnt,
    total_bytes
FROM ranked_urls
WHERE rn <= 5
ORDER BY http_method, request_cnt DESC
