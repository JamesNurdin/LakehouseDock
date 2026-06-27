WITH movies_with_info AS (
    SELECT DISTINCT movie_id
    FROM movie_info_idx
),
company_movie_stats AS (
    SELECT
        ct.kind AS company_type,
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        COUNT(DISTINCT mi.movie_id) AS movies_with_info,
        AVG(t.production_year) AS avg_production_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    LEFT JOIN movies_with_info mi ON t.id = mi.movie_id
    GROUP BY ct.kind, cn.name
),
ranked_companies AS (
    SELECT
        company_type,
        company_name,
        total_movies,
        movies_with_info,
        avg_production_year,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY total_movies DESC) AS rn
    FROM company_movie_stats
)
SELECT
    company_type,
    company_name,
    total_movies,
    movies_with_info,
    avg_production_year,
    CAST(movies_with_info AS double) / NULLIF(total_movies, 0) AS info_coverage
FROM ranked_companies
WHERE rn <= 5
ORDER BY company_type, total_movies DESC
