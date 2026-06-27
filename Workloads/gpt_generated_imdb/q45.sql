WITH actor_movie_details AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        t.id AS movie_id,
        t.production_year,
        cn.name AS character_name,
        mc.company_id,
        ak.id AS aka_id,
        mi.info AS genre
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id AND mi.info_type_id = 1
    WHERE t.production_year IS NOT NULL
)
SELECT
    person_id,
    person_name,
    gender,
    COUNT(DISTINCT movie_id) AS total_movies,
    COUNT(DISTINCT character_name) AS distinct_characters,
    MIN(production_year) AS earliest_year,
    MAX(production_year) AS latest_year,
    COUNT(DISTINCT company_id) AS distinct_companies,
    COUNT(DISTINCT aka_id) AS aka_names_count,
    COUNT(DISTINCT genre) AS distinct_genres
FROM actor_movie_details
GROUP BY person_id, person_name, gender
HAVING COUNT(DISTINCT movie_id) >= 5
ORDER BY total_movies DESC
LIMIT 10
