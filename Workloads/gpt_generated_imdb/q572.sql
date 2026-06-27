WITH actor_stats AS (
  SELECT
    n.id AS person_id,
    n.name AS person_name,
    n.gender,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT cn.id) AS distinct_role_count,
    COUNT(DISTINCT an.id) AS aka_name_count,
    COUNT(DISTINCT pi.id) AS person_info_count
  FROM name n
  JOIN cast_info ci ON ci.person_id = n.id
  JOIN title t ON t.id = ci.movie_id
  JOIN kind_type kt ON kt.id = t.kind_id
  LEFT JOIN char_name cn ON cn.id = ci.person_role_id
  LEFT JOIN aka_name an ON an.person_id = n.id
  LEFT JOIN person_info pi ON pi.person_id = n.id
  WHERE kt.kind = 'movie'
    AND t.production_year BETWEEN 2000 AND 2020
  GROUP BY n.id, n.name, n.gender
),
ranked_actors AS (
  SELECT
    person_id,
    person_name,
    gender,
    movie_count,
    distinct_role_count,
    aka_name_count,
    person_info_count,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY movie_count DESC) AS gender_rank
  FROM actor_stats
)
SELECT
  person_id,
  person_name,
  gender,
  movie_count,
  distinct_role_count,
  aka_name_count,
  person_info_count
FROM ranked_actors
WHERE gender_rank <= 5
ORDER BY gender, movie_count DESC
