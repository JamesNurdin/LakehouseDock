WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ak.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) FILTER (WHERE it.info = 'Birth Date') AS birth_date_info_count
    FROM name n
    LEFT JOIN cast_info ci
        ON ci.person_id = n.id
    LEFT JOIN aka_name ak
        ON ak.person_id = n.id
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    LEFT JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE n.gender IS NOT NULL
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    name,
    gender,
    movie_count,
    aka_name_count,
    birth_date_info_count
FROM actor_stats
ORDER BY movie_count DESC, aka_name_count DESC
LIMIT 20
