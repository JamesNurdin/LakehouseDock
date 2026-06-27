WITH actor_stats AS (
  SELECT
    ci.person_id,
    n.name AS actor_name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_cnt,
    COUNT(DISTINCT ci.person_role_id) AS role_cnt,
    MIN(t.production_year) AS first_year,
    MAX(t.production_year) AS last_year,
    ARRAY_AGG(DISTINCT cn.name) AS distinct_roles,
    COUNT(DISTINCT pi.info_type_id) AS info_type_cnt
  FROM cast_info ci
  JOIN name n ON ci.person_id = n.id
  JOIN title t ON ci.movie_id = t.id
  LEFT JOIN char_name cn ON ci.person_role_id = cn.id
  LEFT JOIN person_info pi ON pi.person_id = n.id
  WHERE t.production_year >= 2000
  GROUP BY ci.person_id, n.name, n.gender
)
SELECT
  actor_name,
  gender,
  movie_cnt,
  role_cnt,
  first_year,
  last_year,
  distinct_roles,
  info_type_cnt
FROM actor_stats
ORDER BY movie_cnt DESC
LIMIT 10
