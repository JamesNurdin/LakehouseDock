WITH actor_movies AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           MIN(t.production_year) AS first_year,
           MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.person_id
),
actor_char_counts AS (
    SELECT person_id,
           character_name,
           char_movie_count,
           ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY char_movie_count DESC) AS rn
    FROM (
        SELECT ci.person_id,
               cn.name AS character_name,
               COUNT(DISTINCT ci.movie_id) AS char_movie_count
        FROM cast_info ci
        JOIN char_name cn ON ci.person_role_id = cn.id
        GROUP BY ci.person_id, cn.name
    )
),
actor_top_char AS (
    SELECT person_id,
           character_name,
           char_movie_count
    FROM actor_char_counts
    WHERE rn = 1
)
SELECT n.id AS actor_id,
       n.name AS actor_name,
       am.movie_count,
       am.first_year,
       am.last_year,
       atc.character_name,
       atc.char_movie_count AS character_movie_count
FROM actor_movies am
JOIN name n ON am.person_id = n.id
LEFT JOIN actor_top_char atc ON am.person_id = atc.person_id
ORDER BY am.movie_count DESC
LIMIT 20
