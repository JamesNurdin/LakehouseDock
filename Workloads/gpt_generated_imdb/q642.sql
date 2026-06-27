WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        kt.kind AS kind,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(
            CASE
                WHEN it.info = 'runtime (minutes)' THEN TRY_CAST(mi.info AS double)
                ELSE NULL
            END
        ) AS runtime_minutes
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
    GROUP BY t.id, kt.kind, t.title, t.production_year
)
SELECT
    kind,
    COUNT(*) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(runtime_minutes) AS avg_runtime_minutes
FROM movie_metrics
WHERE production_year IS NOT NULL
GROUP BY kind
ORDER BY total_movies DESC
LIMIT 10
