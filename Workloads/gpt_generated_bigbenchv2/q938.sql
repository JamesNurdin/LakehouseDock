/*
  Analytical query on the web_logs table.
  It computes, for each distinct log line, the total occurrence count, the average length of the line,
  the percentage that the line contributes to the overall log volume, and its rank by frequency.
  The result is limited to the top 10 most frequent log lines.
*/
WITH line_stats AS (
    SELECT
        line,
        COUNT(*) AS cnt,
        AVG(LENGTH(line)) AS avg_len
    FROM web_logs
    GROUP BY line
)
SELECT
    line,
    cnt,
    avg_len,
    cnt * 100.0 / SUM(cnt) OVER () AS pct_of_total,
    ROW_NUMBER() OVER (ORDER BY cnt DESC) AS rank
FROM line_stats
ORDER BY cnt DESC
LIMIT 10
