WITH phonetic_stats AS (
    SELECT
        k.phonetic_code,
        COUNT(DISTINCT k.id) AS keyword_cnt,
        COUNT(DISTINCT mk.movie_id) AS movie_cnt
    FROM keyword k
    JOIN movie_keyword mk
        ON mk.keyword_id = k.id
    WHERE k.phonetic_code IS NOT NULL
    GROUP BY k.phonetic_code
)
SELECT
    phonetic_code,
    keyword_cnt,
    movie_cnt,
    RANK() OVER (ORDER BY movie_cnt DESC) AS phonetic_rank
FROM phonetic_stats
WHERE movie_cnt > 0
ORDER BY phonetic_rank
LIMIT 10
