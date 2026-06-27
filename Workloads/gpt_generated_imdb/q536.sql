WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.kind_id, t.production_year
)
SELECT
    kt.kind AS genre,
    COUNT(per_movie.movie_id) AS total_movies,
    AVG(per_movie.cast_cnt) AS avg_cast_per_movie,
    AVG(per_movie.kw_cnt) AS avg_keywords_per_movie,
    AVG(per_movie.production_year) AS avg_production_year
FROM per_movie
JOIN kind_type kt ON kt.id = per_movie.kind_id
GROUP BY kt.kind
ORDER BY total_movies DESC
LIMIT 20
