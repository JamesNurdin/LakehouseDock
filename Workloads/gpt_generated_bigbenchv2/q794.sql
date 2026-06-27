WITH words_cte AS (
    SELECT word
    FROM web_logs
    CROSS JOIN UNNEST(regexp_extract_all(line, '\\w+')) AS t(word)
)
SELECT word,
       COUNT(*) AS word_count
FROM words_cte
GROUP BY word
ORDER BY word_count DESC
LIMIT 20
