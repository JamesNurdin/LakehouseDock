/*
  Analytical query on the web_logs table.
  It groups log lines by their character length and whether they contain the word "error",
  counts rows per group, estimates distinct first tokens, and shows a sample line.
*/
WITH processed_logs AS (
    SELECT
        line,
        length(line) AS line_len,
        regexp_extract(line, '^([^ ]+)', 1) AS first_token,
        CASE WHEN lower(line) LIKE '%error%' THEN 'error' ELSE 'other' END AS category
    FROM web_logs
)
SELECT
    line_len,
    category,
    count(*) AS total_rows,
    approx_distinct(first_token) AS distinct_first_tokens,
    min(line) AS example_line
FROM processed_logs
GROUP BY line_len, category
ORDER BY total_rows DESC
LIMIT 20
