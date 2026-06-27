WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE lower(it.info) = 'runtime'
)
SELECT
    kind_type.kind                     AS kind,
    title.production_year              AS production_year,
    COUNT(*)                           AS movie_count,
    AVG(cast_counts.cast_count)        AS avg_cast_per_movie,
    AVG(company_counts.company_count)  AS avg_companies_per_movie,
    AVG(keyword_counts.keyword_count)  AS avg_keywords_per_movie,
    AVG(runtime_info.runtime_minutes)  AS avg_runtime_minutes
FROM title
JOIN kind_type ON title.kind_id = kind_type.id
LEFT JOIN cast_counts   ON cast_counts.movie_id   = title.id
LEFT JOIN company_counts ON company_counts.movie_id = title.id
LEFT JOIN keyword_counts ON keyword_counts.movie_id = title.id
LEFT JOIN runtime_info   ON runtime_info.movie_id   = title.id
WHERE title.production_year BETWEEN 2000 AND 2020
GROUP BY kind_type.kind, title.production_year
ORDER BY kind_type.kind, title.production_year
