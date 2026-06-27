WITH parsed_logs AS (
    SELECT
        line,
        length(line) AS line_length,
        substr(line, 1, 1) AS first_char
    FROM web_logs
    WHERE length(line) > 0
)
SELECT
    first_char,
    count(*) AS total_lines,
    avg(line_length) AS avg_line_length,
    min(line_length) AS min_line_length,
    max(line_length) AS max_line_length
FROM parsed_logs
GROUP BY first_char
ORDER BY total_lines DESC
