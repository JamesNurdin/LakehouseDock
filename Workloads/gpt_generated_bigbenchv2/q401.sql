WITH parsed_logs AS (
    SELECT
        line,
        length(line) AS line_length,
        regexp_extract(line, '^([^\\s]+)', 1) AS first_token
    FROM web_logs
)
SELECT
    first_token,
    line_length,
    count(*) AS line_count
FROM parsed_logs
GROUP BY
    first_token,
    line_length
ORDER BY
    line_count DESC
LIMIT 20
