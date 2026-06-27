WITH actor_role_movies AS (
    SELECT
        name.id AS person_id,
        name.name AS person_name,
        char_name.name AS role_name,
        title.id AS movie_id,
        title.production_year AS production_year
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN char_name ON cast_info.person_role_id = char_name.id
    JOIN title ON cast_info.movie_id = title.id
    JOIN movie_keyword ON movie_keyword.movie_id = title.id
    WHERE movie_keyword.keyword_id = 123
      AND title.production_year IS NOT NULL
),
agg AS (
    SELECT
        person_name,
        role_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        AVG(production_year) AS avg_year,
        MIN(production_year) AS min_year,
        MAX(production_year) AS max_year
    FROM actor_role_movies
    GROUP BY person_name, role_name
)
SELECT
    person_name,
    role_name,
    movie_count,
    avg_year,
    min_year,
    max_year,
    ROW_NUMBER() OVER (PARTITION BY role_name ORDER BY movie_count DESC) AS rank_by_role
FROM agg
WHERE movie_count >= 5
ORDER BY role_name, rank_by_role
LIMIT 20
