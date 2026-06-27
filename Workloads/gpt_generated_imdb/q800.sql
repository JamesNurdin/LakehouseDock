SELECT
    n.id AS person_id,
    n.name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT an.id) AS aka_name_count,
    MAX(CASE WHEN it.info = 'birth date' THEN pi.info END) AS birth_date
FROM name n
LEFT JOIN cast_info ci ON ci.person_id = n.id
LEFT JOIN aka_name an ON an.person_id = n.id
LEFT JOIN person_info pi ON pi.person_id = n.id
LEFT JOIN info_type it ON it.id = pi.info_type_id
GROUP BY n.id, n.name, n.gender
ORDER BY movie_count DESC
LIMIT 100
