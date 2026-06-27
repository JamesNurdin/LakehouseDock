WITH actor_role_counts AS (
    SELECT
        ci.person_id,
        cn.name AS character_name,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
),
actor_top_role AS (
    SELECT
        person_id,
        character_name,
        role_count,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY role_count DESC) AS rn
    FROM actor_role_counts
),
actor_movie_stats AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT kw.keyword) AS distinct_keyword_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year IS NOT NULL
      AND kt.kind = 'movie'
    GROUP BY ci.person_id
)
SELECT
    n.name AS actor_name,
    ams.movie_count,
    ROUND(ams.avg_production_year, 1) AS avg_production_year,
    ams.distinct_keyword_count,
    atr.character_name AS most_frequent_character,
    atr.role_count AS character_appearances
FROM actor_movie_stats ams
JOIN name n ON ams.person_id = n.id
JOIN actor_top_role atr ON ams.person_id = atr.person_id
WHERE atr.rn = 1
ORDER BY ams.movie_count DESC
LIMIT 20
