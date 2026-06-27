WITH prod_company_movies AS (
    SELECT
        mc.company_id,
        c.name AS company_name,
        t.id AS movie_id,
        t.production_year,
        ci.person_id AS actor_id
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    JOIN company_name c
        ON mc.company_id = c.id
    JOIN title t
        ON mc.movie_id = t.id
    JOIN cast_info ci
        ON ci.movie_id = t.id
    JOIN name n
        ON ci.person_id = n.id
    WHERE ct.kind = 'production'
      AND t.production_year >= 2000
)
SELECT
    company_id,
    company_name,
    COUNT(DISTINCT movie_id) AS movie_cnt,
    AVG(production_year) AS avg_production_year,
    COUNT(DISTINCT actor_id) AS distinct_actor_cnt
FROM prod_company_movies
GROUP BY company_id, company_name
HAVING COUNT(DISTINCT movie_id) >= 5
ORDER BY movie_cnt DESC
LIMIT 10
