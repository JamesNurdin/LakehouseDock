WITH parsed AS (
    SELECT
        line,
        length(line) AS line_len,
        cardinality(split(line, ' ')) AS word_count
    FROM web_logs
    WHERE line LIKE '%error%'
),

buckets AS (
    SELECT
        line,
        line_len,
        word_count,
        CASE
            WHEN line_len < 50 THEN '<50'
            WHEN line_len < 100 THEN '50-99'
            WHEN line_len < 200 THEN '100-199'
            ELSE '200+'
        END AS length_bucket
    FROM parsed
)
SELECT
    length_bucket,
    COUNT(*) AS logs_in_bucket,
    AVG(word_count) AS avg_word_count,
    MIN(word_count) AS min_word_count,
    MAX(word_count) AS max_word_count
FROM buckets
GROUP BY length_bucket
ORDER BY logs_in_bucket DESC
