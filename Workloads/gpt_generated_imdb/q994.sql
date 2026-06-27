SELECT
    n.name AS actor_name,
    COUNT(DISTINCT t.id) AS movie_count,
    MIN(t.production_year) AS first_year,
    MAX(t.production_year) AS last_year,
    COUNT(DISTINCT kt.kind) AS distinct_kinds,
    COUNT(DISTINCT ct.kind) AS distinct_company_types
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
WHERE t.production_year >= 2000
GROUP BY n.id, n.name
ORDER BY movie_count DESC
LIMIT 10
