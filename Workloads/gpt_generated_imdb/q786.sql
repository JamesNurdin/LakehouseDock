WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
),
ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k
        ON mk.keyword_id = k.id
)
SELECT
    mk.keyword,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    AVG(r.rating) AS avg_rating
FROM movie_keywords mk
JOIN movies m
    ON mk.movie_id = m.movie_id
JOIN ratings r
    ON m.movie_id = r.movie_id
GROUP BY mk.keyword
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
