WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year,
        COUNT(DISTINCT cn.id) AS distinct_roles
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY n.id, n.name
),
actor_company_counts AS (
    SELECT
        n.id AS person_id,
        cn.id AS company_id,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movies_together
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY n.id, cn.id, cn.name
),
top_company_per_actor AS (
    SELECT
        person_id,
        company_name,
        movies_together,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY movies_together DESC) AS rn
    FROM actor_company_counts
)
SELECT
    a.person_id,
    a.person_name,
    a.movie_count,
    a.first_year,
    a.last_year,
    a.distinct_roles,
    t.company_name,
    t.movies_together
FROM actor_stats a
LEFT JOIN top_company_per_actor t
    ON a.person_id = t.person_id
WHERE t.rn = 1
ORDER BY a.movie_count DESC
LIMIT 10
