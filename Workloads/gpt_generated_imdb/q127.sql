/*
  Analytical query: number of movies, average cast size and average number of production companies
  per production year and title kind.
*/
WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_production_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(pc.prod_company_count, 0) AS prod_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
    LEFT JOIN movie_production_company_counts pc ON t.id = pc.movie_id
    WHERE t.production_year IS NOT NULL
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(prod_company_count) AS avg_production_companies_per_movie
FROM movie_details
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
LIMIT 50
