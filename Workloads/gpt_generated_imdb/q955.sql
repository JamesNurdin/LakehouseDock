/* Top 3 production companies by number of movies per year (2000 and later) */
WITH company_movie_counts AS (
    SELECT
        t.production_year,
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT t.id) AS movie_count
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE t.production_year >= 2000
      AND ct.kind = 'production'
    GROUP BY t.production_year, cn.id, cn.name, ct.kind
),
ranked_companies AS (
    SELECT
        production_year,
        company_id,
        company_name,
        company_type,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM company_movie_counts
)
SELECT
    production_year,
    company_name,
    movie_count
FROM ranked_companies
WHERE rn <= 3
ORDER BY production_year DESC, movie_count DESC
