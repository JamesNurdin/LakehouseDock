WITH person_stats AS (
    SELECT
        name.id AS person_id,
        name.name AS person_name,
        name.gender,
        COUNT(*) AS total_roles,
        COUNT(DISTINCT cast_info.movie_id) AS distinct_movies,
        COUNT(DISTINCT char_name.id) AS distinct_characters
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN char_name ON cast_info.person_role_id = char_name.id
    WHERE cast_info.note IS NOT NULL
    GROUP BY name.id, name.name, name.gender
),
person_top_character AS (
    SELECT
        person_id,
        character_name
    FROM (
        SELECT
            cast_info.person_id AS person_id,
            char_name.name AS character_name,
            COUNT(*) AS role_cnt,
            ROW_NUMBER() OVER (
                PARTITION BY cast_info.person_id
                ORDER BY COUNT(*) DESC
            ) AS rn
        FROM cast_info
        JOIN char_name ON cast_info.person_role_id = char_name.id
        GROUP BY cast_info.person_id, char_name.name
    )
    WHERE rn = 1
)
SELECT
    ps.person_id,
    ps.person_name,
    ps.gender,
    ps.total_roles,
    ps.distinct_movies,
    ps.distinct_characters,
    ptc.character_name AS top_character_name
FROM person_stats ps
LEFT JOIN person_top_character ptc
    ON ps.person_id = ptc.person_id
ORDER BY ps.total_roles DESC
LIMIT 20
