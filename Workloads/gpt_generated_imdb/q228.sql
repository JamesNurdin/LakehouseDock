WITH actor_movie AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        n.id AS name_id,
        cn.id AS char_name_id,
        aka.id AS aka_id
    FROM cast_info c
    JOIN title t
        ON c.movie_id = t.id
    JOIN name n
        ON c.person_id = n.id
    LEFT JOIN char_name cn
        ON c.person_role_id = cn.id
    LEFT JOIN aka_name aka
        ON aka.person_id = n.id
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    LEFT JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE t.kind_id = 1
      AND t.production_year >= 2000
      AND it.info = 'birth date'
)
SELECT
    title,
    production_year,
    COUNT(DISTINCT name_id) AS distinct_actor_count,
    COUNT(DISTINCT char_name_id) AS distinct_character_count,
    COUNT(DISTINCT aka_id) AS distinct_aka_name_count
FROM actor_movie
GROUP BY title, production_year
ORDER BY distinct_actor_count DESC, distinct_character_count DESC
LIMIT 10
