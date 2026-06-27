WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    SUM(cast_count) AS total_cast,
    SUM(company_count) AS total_companies,
    CAST(SUM(cast_count) AS DOUBLE) / NULLIF(COUNT(*), 0) AS avg_cast_per_movie,
    CAST(SUM(company_count) AS DOUBLE) / NULLIF(COUNT(*), 0) AS avg_companies_per_movie
FROM movie_stats
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
LIMIT 100
