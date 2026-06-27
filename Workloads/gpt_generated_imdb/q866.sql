WITH actor_movie_counts AS (
    SELECT
        n.id AS name_id,
        n.name AS primary_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_cnt,
        COUNT(DISTINCT ch.id) AS character_cnt,
        COUNT(DISTINCT ak.id) AS aka_cnt
    FROM cast_info ci
    JOIN name n
      ON ci.person_id = n.id
    JOIN title t
      ON ci.movie_id = t.id
    LEFT JOIN char_name ch
      ON ci.person_role_id = ch.id
    LEFT JOIN aka_name ak
      ON ak.person_id = n.id
    WHERE t.kind_id = 1               -- only movies (kind_id 1)
      AND t.production_year >= 2000   -- movies released in or after 2000
    GROUP BY n.id, n.name, n.gender
),
ranked_actors AS (
    SELECT
        primary_name,
        gender,
        movie_cnt,
        character_cnt,
        aka_cnt,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY movie_cnt DESC, character_cnt DESC) AS gender_rank
    FROM actor_movie_counts
)
SELECT
    primary_name,
    gender,
    movie_cnt,
    character_cnt,
    aka_cnt,
    gender_rank
FROM ranked_actors
WHERE gender_rank <= 3
ORDER BY gender, gender_rank
