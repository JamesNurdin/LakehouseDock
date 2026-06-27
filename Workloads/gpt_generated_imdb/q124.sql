WITH actor_movie_counts AS (
    SELECT
        name.id AS person_id,
        name.name AS person_name,
        name.gender,
        COUNT(DISTINCT cast_info.movie_id) AS movie_count,
        COUNT(DISTINCT cast_info.person_role_id) AS character_count
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    GROUP BY
        name.id,
        name.name,
        name.gender
),
actor_character_counts AS (
    SELECT
        cast_info.person_id,
        char_name.name AS character_name,
        COUNT(*) AS appearances
    FROM cast_info
    JOIN char_name ON cast_info.person_role_id = char_name.id
    GROUP BY
        cast_info.person_id,
        char_name.name
),
actor_top_character AS (
    SELECT
        person_id,
        character_name,
        appearances,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY appearances DESC) AS rn
    FROM actor_character_counts
)
SELECT
    a.person_name,
    a.gender,
    a.movie_count,
    a.character_count,
    t.character_name AS top_character,
    t.appearances AS top_character_appearances
FROM actor_movie_counts AS a
LEFT JOIN actor_top_character AS t
    ON a.person_id = t.person_id
    AND t.rn = 1
ORDER BY a.movie_count DESC
LIMIT 10
