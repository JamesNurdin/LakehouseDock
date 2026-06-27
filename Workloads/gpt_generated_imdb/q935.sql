WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS role_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production company' THEN mc.company_id END) AS production_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution company' THEN mc.company_id END) AS distribution_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON ct.id = mc.company_type_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(role_count) AS avg_roles_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(production_company_count) AS avg_production_companies,
    AVG(distribution_company_count) AS avg_distribution_companies
FROM per_movie
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
LIMIT 20
