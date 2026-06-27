WITH line_lengths AS (
    SELECT
        length(line) AS line_len,
        COUNT(*) AS cnt
    FROM web_logs
    GROUP BY length(line)
)
SELECT line_len, cnt
FROM line_lengths
ORDER BY cnt DESC
LIMIT 10
