WITH
    movies AS (
        SELECT id,
               title,
               production_year
        FROM title
    ),
    cast_counts AS (
        SELECT movie_id,
               COUNT(*) AS cast_count
        FROM cast_info
        GROUP BY movie_id
    ),
    keyword_counts AS (
        SELECT movie_id,
               COUNT(*) AS keyword_count
        FROM movie_keyword
        GROUP BY movie_id
    ),
    company_counts AS (
        SELECT movie_id,
               COUNT(*) AS company_count
        FROM movie_companies
        GROUP BY movie_id
    ),
    runtime_info AS (
        SELECT mi.movie_id,
               CAST(mi.info AS DOUBLE) AS runtime_minutes
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'runtime'
    )
SELECT
    m.production_year,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(kc.keyword_count) AS avg_keywords_per_movie,
    AVG(compc.company_count) AS avg_companies_per_movie,
    AVG(r.runtime_minutes) AS avg_runtime_minutes
FROM movies m
LEFT JOIN cast_counts cc ON cc.movie_id = m.id
LEFT JOIN keyword_counts kc ON kc.movie_id = m.id
LEFT JOIN company_counts compc ON compc.movie_id = m.id
LEFT JOIN runtime_info r ON r.movie_id = m.id
GROUP BY m.production_year
ORDER BY m.production_year
