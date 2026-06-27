WITH person_counts AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.id) AS role_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS info_count,
        COUNT(DISTINCT it.id) AS distinct_info_type_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    LEFT JOIN info_type it ON it.id = pi.info_type_id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    pc.person_id,
    pc.name,
    pc.gender,
    pc.role_count,
    pc.aka_name_count,
    pc.info_count,
    pc.distinct_info_type_count,
    ROW_NUMBER() OVER (ORDER BY pc.role_count DESC) AS role_rank
FROM person_counts pc
WHERE pc.role_count > 0
ORDER BY pc.role_count DESC
LIMIT 50
