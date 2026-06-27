WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT an.id) AS alias_count,
        COUNT(DISTINCT pi.info_type_id) AS info_type_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    WHERE n.gender = 'F'
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    name,
    gender,
    movie_count,
    alias_count,
    info_type_count
FROM person_stats
WHERE movie_count > 0
ORDER BY movie_count DESC
LIMIT 100
