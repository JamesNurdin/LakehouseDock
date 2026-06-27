WITH actor_birth AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        n.gender,
        pi.info AS birth_info
    FROM name n
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    LEFT JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE it.info = 'birth date'
),
actor_aka AS (
    SELECT
        a.person_id AS name_id,
        COUNT(DISTINCT a.id) AS aka_name_count
    FROM aka_name a
    GROUP BY a.person_id
)
SELECT
    ab.actor_name,
    ab.gender,
    COALESCE(ab.birth_info, 'Unknown') AS birth_info,
    COALESCE(aka.aka_name_count, 0) AS aka_name_count,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    MIN(t.production_year) AS first_movie_year,
    MAX(t.production_year) AS last_movie_year
FROM actor_birth ab
LEFT JOIN actor_aka aka
    ON aka.name_id = ab.name_id
JOIN cast_info ci
    ON ci.person_id = ab.name_id
JOIN title t
    ON ci.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY
    ab.actor_name,
    ab.gender,
    ab.birth_info,
    aka.aka_name_count
ORDER BY movie_count DESC
LIMIT 10
