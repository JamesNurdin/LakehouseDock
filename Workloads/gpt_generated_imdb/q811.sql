SELECT
    kt.kind AS movie_kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(t.production_year) AS avg_production_year,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_members,
    COUNT(DISTINCT cn.name) AS distinct_companies
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_info ci
    ON ci.movie_id = t.id
LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
LEFT JOIN company_name cn
    ON cn.id = mc.company_id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY total_movies DESC
