WITH person_movies AS (
        SELECT n.id AS person_id,
               COUNT(DISTINCT ci.movie_id) AS movie_count
        FROM name n
        JOIN cast_info ci ON ci.person_id = n.id
        GROUP BY n.id
    ),
    person_characters AS (
        SELECT n.id AS person_id,
               COUNT(DISTINCT cn.id) AS character_count
        FROM name n
        JOIN cast_info ci ON ci.person_id = n.id
        JOIN char_name cn ON ci.person_role_id = cn.id
        GROUP BY n.id
    ),
    person_aka AS (
        SELECT n.id AS person_id,
               COUNT(DISTINCT a.id) AS aka_name_count
        FROM name n
        JOIN aka_name a ON a.person_id = n.id
        GROUP BY n.id
    ),
    person_birthplace AS (
        SELECT n.id AS person_id,
               MAX(pi.info) AS birthplace
        FROM name n
        JOIN person_info pi ON pi.person_id = n.id
        JOIN info_type it ON pi.info_type_id = it.id
        WHERE it.info = 'birthplace'
        GROUP BY n.id
    )
SELECT n.id AS person_id,
       n.name AS person_name,
       n.gender,
       COALESCE(pm.movie_count, 0) AS movie_count,
       COALESCE(pc.character_count, 0) AS character_count,
       COALESCE(pa.aka_name_count, 0) AS aka_name_count,
       pb.birthplace
FROM name n
LEFT JOIN person_movies pm ON n.id = pm.person_id
LEFT JOIN person_characters pc ON n.id = pc.person_id
LEFT JOIN person_aka pa ON n.id = pa.person_id
LEFT JOIN person_birthplace pb ON n.id = pb.person_id
WHERE n.gender = 'M'
ORDER BY movie_count DESC
LIMIT 10
