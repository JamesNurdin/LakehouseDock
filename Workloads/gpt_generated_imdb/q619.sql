WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(COALESCE(mcc.cast_count, 0)) AS total_cast_members,
    SUM(COALESCE(mco.company_count, 0)) AS total_companies,
    SUM(COALESCE(minf.info_type_count, 0)) AS total_info_types,
    AVG(COALESCE(mcc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(mco.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(minf.info_type_count, 0)) AS avg_info_types_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
LEFT JOIN movie_company_counts mco ON t.id = mco.movie_id
LEFT JOIN movie_info_counts minf ON t.id = minf.movie_id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY total_cast_members DESC
LIMIT 20
