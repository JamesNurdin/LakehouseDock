/*
  Analytical query on the web_logs table.
  It extracts the first whitespace‑separated token from each log line (commonly the HTTP method),
  then counts how many times each token appears and how many distinct log lines contain that token.
*/
WITH parsed_logs AS (
    SELECT
        line,
        split(line, ' ') AS tokens
    FROM web_logs
)
SELECT
    element_at(tokens, 1) AS first_token,
    COUNT(*) AS request_count,
    COUNT(DISTINCT line) AS distinct_line_count
FROM parsed_logs
GROUP BY element_at(tokens, 1)
ORDER BY request_count DESC
LIMIT 20
