WITH actor_movies AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        t.id AS title_id,
        t.production_year AS movie_year,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
),
actor_aggregates AS (
    SELECT
        name_id,
        actor_name,
        COUNT(DISTINCT title_id) AS movie_count,
        MIN(movie_year) AS first_movie_year,
        COUNT(DISTINCT character_name) AS distinct_characters
    FROM actor_movies
    GROUP BY name_id, actor_name
),
aka_counts AS (
    SELECT
        person_id AS name_id,
        COUNT(DISTINCT id) AS aka_name_count
    FROM aka_name
    GROUP BY person_id
)
SELECT
    aa.actor_name,
    aa.movie_count,
    aa.first_movie_year,
    aa.distinct_characters,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count
FROM actor_aggregates aa
LEFT JOIN aka_counts ac ON aa.name_id = ac.name_id
WHERE aa.movie_count >= 5
ORDER BY aa.movie_count DESC, aa.actor_name
LIMIT 10
