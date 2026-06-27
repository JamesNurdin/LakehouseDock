WITH actor_movies AS (
  SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    t.id AS movie_id,
    t.production_year,
    cn.name AS role_name,
    co.id AS company_id
  FROM cast_info ci
  JOIN name n ON ci.person_id = n.id
  JOIN title t ON ci.movie_id = t.id
  JOIN kind_type kt ON t.kind_id = kt.id
  LEFT JOIN char_name cn ON ci.person_role_id = cn.id
  LEFT JOIN movie_companies mc ON t.id = mc.movie_id
  LEFT JOIN company_name co ON mc.company_id = co.id
  WHERE kt.kind = 'movie' AND t.production_year >= 2000
),
actor_agg AS (
  SELECT
    actor_id,
    actor_name,
    COUNT(DISTINCT movie_id) AS total_movies,
    AVG(production_year) AS avg_production_year,
    COUNT(DISTINCT company_id) AS distinct_company_count
  FROM actor_movies
  GROUP BY actor_id, actor_name
  HAVING COUNT(DISTINCT movie_id) >= 5
),
role_counts AS (
  SELECT
    actor_id,
    role_name,
    COUNT(*) AS role_count
  FROM actor_movies
  WHERE role_name IS NOT NULL
  GROUP BY actor_id, role_name
),
actor_top_role AS (
  SELECT
    rc.actor_id,
    rc.role_name,
    rc.role_count,
    ROW_NUMBER() OVER (PARTITION BY rc.actor_id ORDER BY rc.role_count DESC, rc.role_name) AS rn
  FROM role_counts rc
)
SELECT
  a.actor_id,
  a.actor_name,
  a.total_movies,
  a.avg_production_year,
  a.distinct_company_count,
  tr.role_name AS most_frequent_role,
  tr.role_count AS role_appearances
FROM actor_agg a
JOIN actor_top_role tr ON a.actor_id = tr.actor_id
WHERE tr.rn = 1
ORDER BY a.total_movies DESC, a.actor_name
LIMIT 20
