WITH birth_info AS (
    SELECT pi.person_id,
           pi.info AS birthdate
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'birthdate'
)
SELECT
    n.id AS person_id,
    n.name AS person_name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT cn.id) AS character_count,
    COUNT(DISTINCT an.id) AS alternate_name_count,
    MAX(bi.birthdate) AS birthdate
FROM name n
LEFT JOIN cast_info ci       ON ci.person_id = n.id
LEFT JOIN char_name cn       ON ci.person_role_id = cn.id
LEFT JOIN aka_name an        ON an.person_id = n.id
LEFT JOIN birth_info bi      ON bi.person_id = n.id
GROUP BY n.id, n.name, n.gender
ORDER BY movie_count DESC, n.name ASC
LIMIT 100
