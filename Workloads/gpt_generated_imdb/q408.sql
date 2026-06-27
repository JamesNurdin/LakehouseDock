WITH actor_stats AS (
    SELECT
        n.id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    id AS person_id,
    name,
    gender,
    movie_count,
    aka_name_count,
    info_count,
    (movie_count + aka_name_count + info_count) AS total_score
FROM actor_stats
WHERE gender = 'M'
ORDER BY total_score DESC
LIMIT 10
