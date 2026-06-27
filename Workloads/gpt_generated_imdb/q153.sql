WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN it.info = 'runtime' THEN CAST(mi.info AS double) END) AS runtime_minutes
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    md.kind,
    md.production_year,
    COUNT(*) AS movie_count,
    AVG(md.runtime_minutes) AS avg_runtime_minutes,
    AVG(md.cast_count) AS avg_cast_per_movie,
    AVG(md.keyword_count) AS avg_keywords_per_movie
FROM movie_details md
GROUP BY md.kind, md.production_year
ORDER BY movie_count DESC
LIMIT 10
