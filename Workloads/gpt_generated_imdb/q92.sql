SELECT
    kt.kind,
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    AVG(
        (SELECT COUNT(DISTINCT ci.person_id)
         FROM cast_info ci
         WHERE ci.movie_id = t.id)
    ) AS avg_cast_per_movie
FROM movie_keyword mk
JOIN keyword k
    ON mk.keyword_id = k.id
JOIN title t
    ON mk.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
GROUP BY kt.kind, k.keyword
ORDER BY movie_count DESC
LIMIT 20
