WITH actor_movie_counts AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        COUNT(*) AS movie_role_count,
        COUNT(DISTINCT t.id) AS distinct_movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name
),
actor_character_counts AS (
    SELECT
        n.id AS name_id,
        cn.name AS character_name,
        COUNT(*) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY n.id ORDER BY COUNT(*) DESC) AS rn
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id, cn.name
),
top_characters AS (
    SELECT
        name_id,
        character_name,
        role_count
    FROM actor_character_counts
    WHERE rn = 1
),
actor_aka_names AS (
    SELECT
        n.id AS name_id,
        ARRAY_AGG(DISTINCT an.name) AS aka_names
    FROM name n
    LEFT JOIN aka_name an ON an.person_id = n.id
    GROUP BY n.id
)
SELECT
    amc.actor_name,
    amc.movie_role_count,
    amc.distinct_movie_count,
    amc.first_year,
    amc.last_year,
    tc.character_name AS most_frequent_character,
    tc.role_count AS character_role_count,
    an.aka_names
FROM actor_movie_counts amc
LEFT JOIN top_characters tc ON amc.name_id = tc.name_id
LEFT JOIN actor_aka_names an ON amc.name_id = an.name_id
ORDER BY amc.movie_role_count DESC
LIMIT 10
