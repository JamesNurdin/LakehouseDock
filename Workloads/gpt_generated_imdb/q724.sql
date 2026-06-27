/* Analytical query: Find phonetic groups of keywords that are associated with the most distinct movies */
WITH keyword_movies AS (
    SELECT
        kw.phonetic_code,
        mk.movie_id,
        kw.id AS keyword_id
    FROM keyword kw
    JOIN movie_keyword mk
        ON kw.id = mk.keyword_id
    WHERE kw.phonetic_code IS NOT NULL
),
phonetic_stats AS (
    SELECT
        km.phonetic_code,
        COUNT(DISTINCT km.movie_id) AS distinct_movie_cnt,
        COUNT(DISTINCT km.keyword_id) AS keyword_cnt
    FROM keyword_movies km
    GROUP BY km.phonetic_code
    HAVING COUNT(DISTINCT km.movie_id) > 5
)
SELECT
    ps.phonetic_code,
    ps.distinct_movie_cnt,
    ps.keyword_cnt,
    RANK() OVER (ORDER BY ps.distinct_movie_cnt DESC) AS movie_cnt_rank
FROM phonetic_stats ps
ORDER BY ps.distinct_movie_cnt DESC
LIMIT 10
