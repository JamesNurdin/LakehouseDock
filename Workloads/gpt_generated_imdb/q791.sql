WITH movie_company_details AS (
    SELECT
        mc.id AS mc_id,
        mc.movie_id,
        mc.company_id,
        mc.company_type_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        t.title AS movie_title,
        t.production_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    company_type,
    company_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    MIN(production_year) AS first_year,
    MAX(production_year) AS last_year
FROM movie_company_details
GROUP BY company_type, company_name
ORDER BY movie_count DESC
LIMIT 20
