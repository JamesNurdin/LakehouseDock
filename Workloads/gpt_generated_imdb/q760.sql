WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
)
SELECT
    m.title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS num_actors,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS num_production_companies,
    COUNT(DISTINCT mk.keyword_id) AS num_keywords,
    AVG(CAST(mi.info AS DOUBLE)) FILTER (WHERE it.info = 'rating') AS avg_rating
FROM movies m
LEFT JOIN cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON mi.movie_id = m.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
GROUP BY m.title, m.production_year
ORDER BY num_actors DESC
LIMIT 100
