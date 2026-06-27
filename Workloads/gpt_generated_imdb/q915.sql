WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id
),
movie_keywords AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
),
movie_runtime AS (
    SELECT
        t.id AS movie_id,
        AVG(CAST(mi.info AS DOUBLE)) AS runtime_minutes
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'runtime'
    GROUP BY t.id
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(COALESCE(mc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(mk.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(mr.runtime_minutes) AS avg_runtime_minutes
FROM title t
JOIN kind_type kt ON kt.id = t.kind_id
LEFT JOIN movie_cast mc ON mc.movie_id = t.id
LEFT JOIN movie_keywords mk ON mk.movie_id = t.id
LEFT JOIN movie_runtime mr ON mr.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY total_movies DESC
LIMIT 20
