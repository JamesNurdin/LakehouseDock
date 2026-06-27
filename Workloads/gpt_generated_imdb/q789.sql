WITH total_movies AS (
    SELECT COUNT(DISTINCT movie_id) AS total_movie_cnt
    FROM movie_keyword
),
keyword_movie_counts AS (
    SELECT
        k.id,
        k.keyword,
        k.phonetic_code,
        COUNT(DISTINCT mk.movie_id) AS movie_cnt
    FROM keyword k
    JOIN movie_keyword mk
        ON mk.keyword_id = k.id
    GROUP BY
        k.id,
        k.keyword,
        k.phonetic_code
    HAVING COUNT(DISTINCT mk.movie_id) > 5
)
SELECT
    kmc.id,
    kmc.keyword,
    kmc.phonetic_code,
    kmc.movie_cnt,
    (kmc.movie_cnt * 100.0 / tm.total_movie_cnt) AS movie_pct
FROM keyword_movie_counts kmc
CROSS JOIN total_movies tm
ORDER BY kmc.movie_cnt DESC
LIMIT 20
