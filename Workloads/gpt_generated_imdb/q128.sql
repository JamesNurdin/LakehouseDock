WITH person_role_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.role_id) AS distinct_role_count,
        AVG(ci.person_role_id) AS avg_role_score,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.info_type_id) AS distinct_info_type_count,
        COUNT(DISTINCT pi.id) AS info_entry_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
    HAVING COUNT(DISTINCT ci.movie_id) >= 5
)
SELECT
    person_id,
    primary_name,
    gender,
    movie_count,
    distinct_role_count,
    avg_role_score,
    aka_name_count,
    distinct_info_type_count,
    info_entry_count
FROM person_role_stats
ORDER BY avg_role_score DESC, movie_count DESC
LIMIT 10
