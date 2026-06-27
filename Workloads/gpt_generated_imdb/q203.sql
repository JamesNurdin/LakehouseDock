WITH alt_names AS (
    SELECT 
        an.person_id,
        array_agg(DISTINCT an.name) AS alt_name_list
    FROM aka_name an
    GROUP BY an.person_id
),
person_infos AS (
    SELECT 
        pi.person_id,
        array_agg(DISTINCT pi.info) AS info_list
    FROM person_info pi
    GROUP BY pi.person_id
),
person_movies AS (
    SELECT 
        ci.person_id,
        count(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
)
SELECT 
    n.id AS person_id,
    n.name,
    n.gender,
    pm.movie_count,
    an.alt_name_list,
    pi.info_list
FROM name n
LEFT JOIN person_movies pm ON pm.person_id = n.id
LEFT JOIN alt_names an ON an.person_id = n.id
LEFT JOIN person_infos pi ON pi.person_id = n.id
WHERE n.gender = 'M'
ORDER BY pm.movie_count DESC
LIMIT 10
