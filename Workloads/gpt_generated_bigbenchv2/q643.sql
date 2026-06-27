WITH parsed_logs AS (
    SELECT
        line,
        regexp_extract(line, '^([^ ]+)', 1) AS ip,
        CAST(regexp_extract(line, '"[A-Z]+ [^ ]+ HTTP/[^\"]+" ([0-9]{3})', 1) AS integer) AS status_code,
        CAST(regexp_extract(line, '"[A-Z]+ [^ ]+ HTTP/[^\"]+" [0-9]{3} ([0-9]+)', 1) AS integer) AS bytes_sent
    FROM web_logs
    WHERE line IS NOT NULL
),
agg_ip AS (
    SELECT
        ip,
        COUNT(*) AS total_requests,
        SUM(bytes_sent) AS total_bytes,
        AVG(bytes_sent) AS avg_bytes
    FROM parsed_logs
    WHERE ip IS NOT NULL
    GROUP BY ip
)
SELECT
    ip,
    total_requests,
    total_bytes,
    avg_bytes,
    RANK() OVER (ORDER BY total_requests DESC) AS request_rank
FROM agg_ip
ORDER BY total_requests DESC
LIMIT 20
