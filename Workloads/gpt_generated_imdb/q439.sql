WITH actor_char_counts AS (
    SELECT
        ci.person_id,
        n.name AS actor_name,
        n.gender,
        cn.name AS character_name,
        COUNT(*) AS appearances
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, n.name, n.gender, cn.name
),
actor_top_char AS (
    SELECT
        ac.person_id,
        ac.actor_name,
        ac.gender,
        ac.character_name,
        ac.appearances,
        ROW_NUMBER() OVER (PARTITION BY ac.person_id ORDER BY ac.appearances DESC, ac.character_name) AS rn
    FROM actor_char_counts ac
),
actor_overall AS (
    SELECT
        ci.person_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS distinct_movie_cnt,
        COUNT(DISTINCT ci.person_role_id) AS distinct_character_cnt,
        MIN(t.production_year) AS first_movie_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.person_id, n.name, n.gender
)
SELECT
    o.actor_name,
    o.gender,
    o.distinct_movie_cnt,
    o.distinct_character_cnt,
    o.first_movie_year,
    topc.character_name AS most_frequent_character,
    topc.appearances AS character_appearance_cnt,
    ROW_NUMBER() OVER (ORDER BY o.distinct_movie_cnt DESC) AS movie_rank
FROM actor_overall o
JOIN actor_top_char topc ON o.person_id = topc.person_id
WHERE topc.rn = 1
ORDER BY o.distinct_movie_cnt DESC
LIMIT 10
