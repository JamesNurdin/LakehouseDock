SELECT
    it.id AS info_type_id,
    it.info AS info_type,
    COUNT(DISTINCT CASE WHEN t.production_year >= 2000 THEN mi.movie_id END) AS movie_count,
    COUNT(DISTINCT pi.person_id) AS person_count,
    COUNT(DISTINCT an.name) AS aka_name_count,
    CASE
        WHEN COUNT(DISTINCT pi.person_id) = 0 THEN NULL
        ELSE COUNT(DISTINCT CASE WHEN t.production_year >= 2000 THEN mi.movie_id END) * 1.0 / COUNT(DISTINCT pi.person_id)
    END AS movies_per_person
FROM info_type it
LEFT JOIN movie_info mi ON mi.info_type_id = it.id
LEFT JOIN title t ON mi.movie_id = t.id
LEFT JOIN person_info pi ON pi.info_type_id = it.id
LEFT JOIN name n ON pi.person_id = n.id
LEFT JOIN aka_name an ON an.person_id = n.id
GROUP BY it.id, it.info
ORDER BY it.info
