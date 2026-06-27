WITH actor_movies AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        t.production_year,
        kt.kind,
        mc.company_id,
        mk.keyword_id,
        n.name AS actor_name,
        n.gender AS actor_gender
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE n.gender = 'M'
      AND t.production_year >= 2000
)
SELECT
    am.actor_name,
    am.actor_gender,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    AVG(am.production_year) AS avg_production_year,
    COUNT(DISTINCT am.kind) AS distinct_kind_count,
    COUNT(DISTINCT am.company_id) AS distinct_company_count,
    COUNT(DISTINCT am.keyword_id) AS distinct_keyword_count
FROM actor_movies am
GROUP BY am.actor_name, am.actor_gender
ORDER BY movie_count DESC
LIMIT 10
