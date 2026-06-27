WITH length_counts AS (
    SELECT length(line) AS line_len,
           count(*) AS cnt
    FROM web_logs
    GROUP BY length(line)
)
SELECT line_len,
       cnt,
       cnt * 1.0 / sum(cnt) OVER () AS proportion
FROM length_counts
ORDER BY cnt DESC
LIMIT 20
