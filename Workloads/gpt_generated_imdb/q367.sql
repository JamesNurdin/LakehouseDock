WITH character_appearances AS (
    SELECT
        cn.id AS char_id,
        cn.name AS character_name,
        cn.imdb_id AS imdb_character_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_count,
        AVG(ci.nr_order) AS avg_nr_order,
        MIN(ci.nr_order) AS min_nr_order,
        MAX(ci.nr_order) AS max_nr_order
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE ci.role_id = 1
    GROUP BY cn.id, cn.name, cn.imdb_id
)
SELECT
    char_id,
    character_name,
    imdb_character_id,
    movie_count,
    distinct_actor_count,
    avg_nr_order,
    min_nr_order,
    max_nr_order,
    RANK() OVER (ORDER BY movie_count DESC) AS movie_count_rank
FROM character_appearances
ORDER BY movie_count DESC, distinct_actor_count DESC
LIMIT 20
