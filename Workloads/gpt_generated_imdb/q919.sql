WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year > 2000
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
movie_cast AS (
    SELECT
        ci.movie_id,
        ci.person_id
    FROM cast_info ci
)
SELECT
    kw.keyword,
    kw.movie_count,
    kw.distinct_cast_count,
    kw.avg_cast_per_movie,
    100.0 * kw.movie_count / SUM(kw.movie_count) OVER () AS pct_of_total_movies
FROM (
    SELECT
        mk.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count,
        COUNT(DISTINCT mc.person_id) AS distinct_cast_count,
        CAST(COUNT(DISTINCT mc.person_id) AS double) / COUNT(DISTINCT mk.movie_id) AS avg_cast_per_movie
    FROM movies m
    JOIN movie_keywords mk ON mk.movie_id = m.movie_id
    JOIN movie_cast mc ON mc.movie_id = m.movie_id
    GROUP BY mk.keyword
) kw
ORDER BY kw.movie_count DESC
LIMIT 10
