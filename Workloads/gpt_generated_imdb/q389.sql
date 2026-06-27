WITH rating_movies AS (
    SELECT mi.movie_id,
           try_cast(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_details AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
),
role_counts AS (
    SELECT ci.person_id,
           cn.name AS character_name,
           COUNT(*) AS role_cnt
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
),
top_role AS (
    SELECT rc.person_id,
           rc.character_name,
           rc.role_cnt,
           ROW_NUMBER() OVER (PARTITION BY rc.person_id ORDER BY rc.role_cnt DESC, rc.character_name) AS rn
    FROM role_counts rc
)
SELECT n.id AS person_id,
       n.name,
       n.gender,
       tr.character_name AS most_frequent_role,
       tr.role_cnt AS role_appearances,
       COUNT(DISTINCT ci.movie_id) AS movie_count,
       AVG(rm.rating) AS avg_rating,
       MIN(md.production_year) AS first_year,
       MAX(md.production_year) AS last_year
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN movie_details md ON ci.movie_id = md.movie_id
LEFT JOIN rating_movies rm ON ci.movie_id = rm.movie_id
LEFT JOIN top_role tr ON ci.person_id = tr.person_id AND tr.rn = 1
GROUP BY n.id, n.name, n.gender, tr.character_name, tr.role_cnt
HAVING COUNT(DISTINCT ci.movie_id) >= 5
ORDER BY avg_rating DESC NULLS LAST
LIMIT 20
