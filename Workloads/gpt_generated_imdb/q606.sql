WITH actor_movie_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.person_role_id) AS distinct_role_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    GROUP BY n.id, n.name, n.gender
),
actor_role_counts AS (
    SELECT
        n.id AS person_id,
        cn.id AS role_id,
        cn.name AS role_name,
        COUNT(*) AS role_occurrences
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id, cn.id, cn.name
),
actor_top_role AS (
    SELECT
        person_id,
        role_name,
        role_occurrences,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY role_occurrences DESC, role_name) AS rn
    FROM actor_role_counts
)
SELECT
    amc.person_name,
    amc.gender,
    amc.movie_count,
    amc.distinct_role_count,
    atr.role_name AS most_frequent_role,
    atr.role_occurrences AS role_occurrence_count
FROM actor_movie_counts amc
LEFT JOIN actor_top_role atr
    ON amc.person_id = atr.person_id AND atr.rn = 1
ORDER BY amc.movie_count DESC
LIMIT 10
