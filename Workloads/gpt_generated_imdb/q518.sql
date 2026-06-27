WITH cast_per_movie AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_per_movie AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
)
SELECT
    kt.kind AS movie_kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS num_movies,
    AVG(cp.cast_count) AS avg_cast_per_movie,
    AVG(cp2.company_count) AS avg_companies_per_movie,
    COUNT(DISTINCT ci.person_id) AS total_distinct_cast_members,
    COUNT(DISTINCT mc.company_id) AS total_distinct_companies
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_per_movie cp
    ON t.id = cp.movie_id
LEFT JOIN company_per_movie cp2
    ON t.id = cp2.movie_id
LEFT JOIN cast_info ci
    ON t.id = ci.movie_id
LEFT JOIN movie_companies mc
    ON t.id = mc.movie_id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
