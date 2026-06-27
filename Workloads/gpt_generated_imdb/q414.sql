WITH person_metrics AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS person_info_count,
        COUNT(DISTINCT pi.info_type_id) AS person_info_type_count,
        COUNT(DISTINCT it.info) AS distinct_info_type_name_count,
        ARRAY_AGG(DISTINCT it.info) FILTER (WHERE it.info IS NOT NULL) AS info_type_names
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    LEFT JOIN info_type it ON pi.info_type_id = it.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    person_name,
    movie_count,
    aka_name_count,
    person_info_count,
    person_info_type_count,
    distinct_info_type_name_count,
    info_type_names
FROM person_metrics
ORDER BY movie_count DESC, person_name
LIMIT 100
