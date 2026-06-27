WITH movie_counts AS (
    SELECT ci.person_id AS person_id,
           COUNT(DISTINCT ci.movie_id) AS movie_cnt
    FROM cast_info ci
    GROUP BY ci.person_id
),
aka_counts AS (
    SELECT an.person_id AS person_id,
           COUNT(*) AS aka_cnt
    FROM aka_name an
    GROUP BY an.person_id
),
person_stats AS (
    SELECT n.id AS person_id,
           n.name AS person_name,
           n.gender,
           COALESCE(mc.movie_cnt, 0) AS movie_cnt,
           COALESCE(ac.aka_cnt, 0) AS aka_cnt
    FROM name n
    LEFT JOIN movie_counts mc ON mc.person_id = n.id
    LEFT JOIN aka_counts ac ON ac.person_id = n.id
)
SELECT ps.person_id,
       ps.person_name,
       ps.gender,
       ps.movie_cnt,
       ps.aka_cnt,
       ROW_NUMBER() OVER (ORDER BY ps.movie_cnt DESC, ps.aka_cnt DESC) AS rank
FROM person_stats ps
WHERE ps.movie_cnt > 0
ORDER BY rank
LIMIT 10
