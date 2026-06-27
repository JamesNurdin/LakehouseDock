WITH cast_birthdate AS (
    SELECT DISTINCT ci.person_id,
                    ci.movie_id,
                    ci.person_role_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'birthdate'
),
aka_counts AS (
    SELECT person_id,
           COUNT(DISTINCT id) AS aka_cnt
    FROM aka_name
    GROUP BY person_id
)
SELECT cn.id AS char_id,
       cn.name AS character_name,
       COUNT(DISTINCT cb.person_id) AS actor_count,
       COUNT(DISTINCT cb.movie_id) AS movie_count,
       SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_actor_count,
       SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_actor_count,
       AVG(COALESCE(ac.aka_cnt, 0)) AS avg_alternate_names_per_actor
FROM cast_birthdate cb
JOIN char_name cn ON cb.person_role_id = cn.id
JOIN name n ON cb.person_id = n.id
LEFT JOIN aka_counts ac ON cb.person_id = ac.person_id
GROUP BY cn.id, cn.name
ORDER BY actor_count DESC
LIMIT 20
