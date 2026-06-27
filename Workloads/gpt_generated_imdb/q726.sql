WITH movies_per_person AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
),
aka_per_person AS (
    SELECT an.person_id,
           COUNT(*) AS aka_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
info_per_person AS (
    SELECT pi.person_id,
           COUNT(*) AS info_count,
           COUNT(DISTINCT pi.info_type_id) AS distinct_info_type_count
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT n.id,
       n.name,
       n.gender,
       COALESCE(m.movie_count, 0) AS movie_count,
       COALESCE(a.aka_name_count, 0) AS aka_name_count,
       COALESCE(i.info_count, 0) AS info_count,
       COALESCE(i.distinct_info_type_count, 0) AS distinct_info_type_count
FROM name n
LEFT JOIN movies_per_person m ON m.person_id = n.id
LEFT JOIN aka_per_person a ON a.person_id = n.id
LEFT JOIN info_per_person i ON i.person_id = n.id
ORDER BY movie_count DESC, aka_name_count DESC
LIMIT 10
