WITH filtered_logs AS (
    SELECT line
    FROM web_logs
    WHERE line LIKE '%ERROR%'
),
line_lengths AS (
    SELECT line,
           length(line) AS line_len
    FROM filtered_logs
),
length_distribution AS (
    SELECT line_len,
           count(*) AS total_lines,
           count(DISTINCT line) AS distinct_lines,
           min(line) AS example_min_line,
           max(line) AS example_max_line
    FROM line_lengths
    GROUP BY line_len
)
SELECT line_len,
       total_lines,
       distinct_lines,
       example_min_line,
       example_max_line
FROM length_distribution
ORDER BY total_lines DESC
LIMIT 15
