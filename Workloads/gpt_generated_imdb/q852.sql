WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(*) AS total_appearances,
        COUNT(DISTINCT ci.movie_id) AS distinct_movies,
        COUNT(DISTINCT ci.person_role_id) AS distinct_characters
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    GROUP BY n.id, n.name
),
actor_character_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        cn.name AS character_name,
        COUNT(*) AS appearances
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    GROUP BY n.id, n.name, cn.name
),
max_character_appearances AS (
    SELECT
        person_id,
        MAX(appearances) AS max_appearances
    FROM actor_character_counts
    GROUP BY person_id
),
top_character AS (
    SELECT
        acc.person_id,
        acc.person_name,
        acc.character_name,
        acc.appearances AS top_character_appearances
    FROM actor_character_counts acc
    JOIN max_character_appearances mca
        ON acc.person_id = mca.person_id
        AND acc.appearances = mca.max_appearances
)
SELECT
    s.person_name,
    s.total_appearances,
    s.distinct_movies,
    s.distinct_characters,
    t.character_name AS top_character,
    t.top_character_appearances
FROM actor_stats s
JOIN top_character t
    ON s.person_id = t.person_id
ORDER BY s.total_appearances DESC
LIMIT 20
