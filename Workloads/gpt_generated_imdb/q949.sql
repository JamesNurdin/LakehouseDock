WITH movie_counts AS (
    SELECT n.id AS person_id,
           n.name,
           n.gender,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           MIN(t.production_year) AS first_year
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name, n.gender
),
aka_counts AS (
    SELECT n.id AS person_id,
           COUNT(DISTINCT a.id) AS aka_count
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    GROUP BY n.id
),
info_counts AS (
    SELECT n.id AS person_id,
           COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id
)
SELECT mc.name,
       mc.gender,
       mc.movie_count,
       mc.first_year,
       ac.aka_count,
       ic.info_count
FROM movie_counts mc
LEFT JOIN aka_counts ac ON ac.person_id = mc.person_id
LEFT JOIN info_counts ic ON ic.person_id = mc.person_id
ORDER BY mc.movie_count DESC, mc.name
LIMIT 10
