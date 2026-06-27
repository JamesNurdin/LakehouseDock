WITH actor_movie_character_rating AS (
    SELECT
        name.id AS person_id,
        COALESCE(aka_name.name, name.name) AS person_name,
        char_name.name AS character_name,
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        movie_info_idx.note AS rating
    FROM cast_info
    JOIN name
        ON cast_info.person_id = name.id
    LEFT JOIN aka_name
        ON aka_name.person_id = name.id
    LEFT JOIN char_name
        ON cast_info.person_role_id = char_name.id
    JOIN title
        ON cast_info.movie_id = title.id
    JOIN movie_info_idx
        ON movie_info_idx.movie_id = title.id
    JOIN info_type
        ON movie_info_idx.info_type_id = info_type.id
    WHERE info_type.info = 'Rating'
)
SELECT
    person_name,
    character_name,
    production_year,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(rating) AS avg_rating
FROM actor_movie_character_rating
WHERE rating IS NOT NULL
GROUP BY person_name, character_name, production_year
ORDER BY person_name, production_year, character_name
