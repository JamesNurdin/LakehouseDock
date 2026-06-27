SELECT
    t.production_year,
    k.keyword,
    COUNT(DISTINCT t.id) AS num_movies,
    COUNT(DISTINCT ci.person_id) AS num_distinct_cast,
    AVG(ci.nr_order) AS avg_nr_order
FROM title t
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON k.id = mk.keyword_id
JOIN cast_info ci ON ci.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.production_year, k.keyword
HAVING COUNT(DISTINCT t.id) >= 10
ORDER BY t.production_year DESC, num_movies DESC
LIMIT 100
