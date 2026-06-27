WITH person_activity AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ak.id) AS aka_count,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    person_name,
    movie_count,
    aka_count,
    info_count
FROM person_activity
ORDER BY movie_count DESC, aka_count DESC
LIMIT 20
