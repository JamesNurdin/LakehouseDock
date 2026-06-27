WITH filtered_movies AS (
    SELECT
        t.id,
        t.production_year,
        kw.keyword
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
)
SELECT
    fm.keyword AS genre,
    COUNT(DISTINCT fm.id) AS movie_count,
    AVG(fm.production_year) AS avg_production_year,
    COUNT(DISTINCT n.id) AS distinct_actor_count,
    COUNT(DISTINCT mc.company_id) AS distinct_company_count
FROM filtered_movies fm
LEFT JOIN cast_info ci ON ci.movie_id = fm.id
LEFT JOIN name n ON ci.person_id = n.id
LEFT JOIN movie_companies mc ON mc.movie_id = fm.id
GROUP BY fm.keyword
ORDER BY movie_count DESC
LIMIT 20
