WITH movie_details AS (
    SELECT
        t.title,
        t.production_year,
        kt.kind AS genre,
        ci.person_id,
        mk.keyword_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year >= 2000
)
SELECT
    title,
    production_year,
    genre,
    COUNT(DISTINCT person_id) AS cast_member_count,
    COUNT(DISTINCT keyword_id) AS keyword_count,
    array_agg(DISTINCT company_name) FILTER (WHERE company_type = 'production') AS production_companies,
    array_agg(DISTINCT company_name) FILTER (WHERE company_type = 'distribution') AS distribution_companies
FROM movie_details
GROUP BY title, production_year, genre
HAVING COUNT(DISTINCT person_id) >= 5
ORDER BY production_year DESC, cast_member_count DESC
LIMIT 100
