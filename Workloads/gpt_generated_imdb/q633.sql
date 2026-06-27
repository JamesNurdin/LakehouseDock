WITH role_counts AS (
    SELECT n.id AS name_id,
           ci.role_id,
           COUNT(*) AS role_cnt
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    GROUP BY n.id, ci.role_id
),
most_frequent_role AS (
    SELECT name_id,
           role_id AS most_frequent_role_id,
           role_cnt,
           ROW_NUMBER() OVER (PARTITION BY name_id ORDER BY role_cnt DESC) AS rn
    FROM role_counts
),
actor_summary AS (
    SELECT n.id AS name_id,
           n.name AS actor_name,
           n.gender,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           COUNT(DISTINCT an.id) AS aka_name_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT a.name_id,
       a.actor_name,
       a.gender,
       a.movie_count,
       a.aka_name_count,
       mf.most_frequent_role_id
FROM actor_summary a
LEFT JOIN (
    SELECT name_id, most_frequent_role_id
    FROM most_frequent_role
    WHERE rn = 1
) mf ON mf.name_id = a.name_id
ORDER BY a.movie_count DESC
LIMIT 10
