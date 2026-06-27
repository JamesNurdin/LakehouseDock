WITH movie_company_counts AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        kt.kind,
        COUNT(mc.id) AS company_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.production_year, kt.kind
),
yearly_stats AS (
    SELECT
        kind,
        production_year,
        COUNT(*) AS movie_count,
        SUM(distinct_company_count) AS total_distinct_companies,
        AVG(company_count) AS avg_company_per_movie
    FROM movie_company_counts
    GROUP BY kind, production_year
)
SELECT
    kind,
    production_year,
    movie_count,
    total_distinct_companies,
    avg_company_per_movie
FROM yearly_stats
ORDER BY kind, production_year
