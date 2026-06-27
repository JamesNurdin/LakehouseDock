WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.person_role_id) AS role_id_count,
        COUNT(DISTINCT cn.name) AS distinct_character_name_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN title t ON t.id = ci.movie_id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    WHERE n.gender IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    person_name,
    gender,
    movie_count,
    role_id_count,
    distinct_character_name_count,
    first_year,
    last_year,
    aka_name_count,
    info_count
FROM person_stats
ORDER BY movie_count DESC
LIMIT 10
