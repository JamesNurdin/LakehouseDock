WITH movie_company_kind AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind_name,
        ct.kind AS company_type_name,
        cn.name AS company_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE t.production_year >= 2000
)
SELECT
    mk.kind_name,
    mk.company_type_name,
    COUNT(DISTINCT mk.movie_id) AS num_movies,
    AVG(mk.production_year) AS avg_production_year,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_members
FROM movie_company_kind mk
JOIN cast_info ci ON ci.movie_id = mk.movie_id
GROUP BY mk.kind_name, mk.company_type_name
ORDER BY num_movies DESC
LIMIT 20
