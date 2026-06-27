WITH actor_movie_stats AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT cn.id) AS distinct_company_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY ci.person_id
),
aka_counts AS (
    SELECT
        person_id,
        COUNT(*) AS aka_count
    FROM aka_name
    GROUP BY person_id
)
SELECT
    n.name,
    n.gender,
    ams.movie_count,
    ams.avg_production_year,
    ams.distinct_company_count,
    COALESCE(aka.aka_count, 0) AS aka_name_count
FROM actor_movie_stats ams
JOIN name n ON ams.person_id = n.id
LEFT JOIN aka_counts aka ON n.id = aka.person_id
WHERE ams.movie_count >= 5
ORDER BY ams.movie_count DESC
LIMIT 10
