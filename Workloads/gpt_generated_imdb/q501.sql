WITH kw_stats AS (
    SELECT
        mk.keyword_id,
        COUNT(*) AS assignment_count,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM movie_keyword mk
    GROUP BY mk.keyword_id
)
SELECT
    k.id,
    k.keyword,
    k.phonetic_code,
    ks.assignment_count,
    ks.movie_count,
    CAST(ks.movie_count AS double) / ks.assignment_count AS movie_per_assignment_ratio
FROM keyword k
JOIN kw_stats ks
    ON k.id = ks.keyword_id
WHERE ks.assignment_count > 0
ORDER BY movie_per_assignment_ratio DESC
LIMIT 10
