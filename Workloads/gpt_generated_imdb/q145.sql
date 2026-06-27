SELECT
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    COUNT(DISTINCT mc.company_id) AS distinct_company_count
FROM title t
JOIN movie_keyword mk
    ON mk.movie_id = t.id
JOIN keyword k
    ON k.id = mk.keyword_id
LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY k.keyword
ORDER BY COUNT(DISTINCT t.id) DESC
LIMIT 10
