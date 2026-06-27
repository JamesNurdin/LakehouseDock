WITH keyword_movie_counts AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM keyword k
    JOIN movie_keyword mk
        ON mk.keyword_id = k.id
    GROUP BY k.id, k.keyword
),
total_movies AS (
    SELECT COUNT(DISTINCT movie_id) AS total_movie_count
    FROM movie_keyword
)
SELECT
    kmc.keyword_id,
    kmc.keyword,
    kmc.movie_count,
    kmc.movie_count * 1.0 / tm.total_movie_count AS movie_ratio,
    RANK() OVER (ORDER BY kmc.movie_count DESC) AS rank_by_movie_count
FROM keyword_movie_counts kmc
CROSS JOIN total_movies tm
ORDER BY kmc.movie_count DESC
LIMIT 10
