WITH actor_movie_stats AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY ci.person_id
),
actor_keyword_counts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY ci.person_id
),
actor_production_company_counts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT mc.company_id) AS distinct_production_company_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE kt.kind = 'movie' 
      AND ct.kind = 'production company' 
      AND t.production_year >= 2000
    GROUP BY ci.person_id
)
SELECT
    n.name AS actor_name,
    ams.movie_count,
    ams.avg_production_year,
    COALESCE(akc.distinct_keyword_count, 0) AS distinct_keyword_count,
    COALESCE(apc.distinct_production_company_count, 0) AS distinct_production_company_count
FROM actor_movie_stats ams
JOIN name n ON ams.person_id = n.id
LEFT JOIN actor_keyword_counts akc ON akc.person_id = ams.person_id
LEFT JOIN actor_production_company_counts apc ON apc.person_id = ams.person_id
ORDER BY ams.movie_count DESC
LIMIT 10
