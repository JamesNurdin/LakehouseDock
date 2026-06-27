WITH actor_role_agg AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.person_role_id) AS distinct_characters,
        COUNT(DISTINCT ci.movie_id) AS distinct_movies,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY ci.person_id
),
aka_counts AS (
    SELECT
        ak.person_id,
        COUNT(*) AS aka_name_count
    FROM aka_name ak
    GROUP BY ak.person_id
)
SELECT
    n.name AS actor_name,
    ar.distinct_characters,
    ar.distinct_movies,
    ar.first_year,
    ar.last_year,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count
FROM actor_role_agg ar
JOIN name n ON ar.person_id = n.id
LEFT JOIN aka_counts ac ON n.id = ac.person_id
ORDER BY ar.distinct_characters DESC, ar.distinct_movies DESC
LIMIT 10
