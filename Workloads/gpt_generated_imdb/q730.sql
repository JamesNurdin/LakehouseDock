WITH actor_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.person_role_id) AS character_count,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN movie_companies mc
        ON mc.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY n.id, n.name
),
ranked_actors AS (
    SELECT
        actor_id,
        actor_name,
        movie_count,
        character_count,
        distinct_companies,
        first_year,
        last_year,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC, character_count DESC) AS actor_rank
    FROM actor_stats
)
SELECT
    actor_rank,
    actor_name,
    movie_count,
    character_count,
    distinct_companies,
    first_year,
    last_year
FROM ranked_actors
WHERE actor_rank <= 10
ORDER BY actor_rank
