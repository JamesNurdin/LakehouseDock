WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_cnt,
        COUNT(DISTINCT an.id) AS aka_cnt
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    name,
    gender,
    movie_cnt,
    aka_cnt,
    ROW_NUMBER() OVER (ORDER BY movie_cnt DESC) AS rank_by_movies
FROM actor_stats
WHERE movie_cnt > 0
ORDER BY rank_by_movies
LIMIT 10
