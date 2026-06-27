WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS double) END) AS rating
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(rating) AS avg_rating
FROM movie_metrics
WHERE rating IS NOT NULL
GROUP BY kind, production_year
ORDER BY avg_rating DESC
LIMIT 20
