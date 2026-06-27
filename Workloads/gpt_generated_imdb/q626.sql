WITH cast_size AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_size
    FROM cast_info
    GROUP BY movie_id
),
keyword_count AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    n.name AS actor_name,
    kt.kind AS production_kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(cs.cast_size) AS avg_cast_size,
    AVG(kc.keyword_count) AS avg_keywords_per_movie
FROM cast_info ci
JOIN name n
    ON ci.person_id = n.id
JOIN title t
    ON ci.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_size cs
    ON t.id = cs.movie_id
LEFT JOIN keyword_count kc
    ON t.id = kc.movie_id
WHERE n.gender = 'M'
  AND t.production_year >= 2000
  AND t.production_year < 2010
GROUP BY n.name, kt.kind
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY total_movies DESC
LIMIT 20
