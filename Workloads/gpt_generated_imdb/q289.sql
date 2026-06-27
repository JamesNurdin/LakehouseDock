WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT cn.name) AS company_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk
        ON t.id = mk.movie_id
    LEFT JOIN keyword k
        ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc
        ON t.id = mc.movie_id
    LEFT JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE kt.kind = 'movie'
    GROUP BY n.id, n.name
)
SELECT
    actor_name,
    movie_count,
    keyword_count,
    company_count,
    avg_production_year
FROM actor_stats
ORDER BY movie_count DESC, keyword_count DESC
LIMIT 10
