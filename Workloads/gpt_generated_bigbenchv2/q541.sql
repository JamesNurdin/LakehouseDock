/*
  Analytical query on the web_logs table.
  It extracts the first token from each log line (commonly the HTTP method),
  aggregates counts, distinct line counts, and average line length per token,
  then ranks the tokens by frequency.
*/
WITH token_counts AS (
    SELECT
        split_part(line, ' ', 1) AS token,
        COUNT(*) AS cnt,
        COUNT(DISTINCT line) AS distinct_lines,
        AVG(length(line)) AS avg_line_len
    FROM web_logs
    GROUP BY split_part(line, ' ', 1)
)
SELECT
    token,
    cnt,
    distinct_lines,
    avg_line_len,
    ROW_NUMBER() OVER (ORDER BY cnt DESC) AS token_rank
FROM token_counts
WHERE cnt > 5
ORDER BY token_rank
LIMIT 20
