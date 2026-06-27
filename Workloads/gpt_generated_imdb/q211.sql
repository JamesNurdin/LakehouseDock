WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
movie_info_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_type_count
    FROM movie_info_idx
    GROUP BY movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(compc.company_count) AS avg_companies_per_movie,
    AVG(mi.info_type_count) AS avg_info_types_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN movie_info_counts mi ON mi.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
