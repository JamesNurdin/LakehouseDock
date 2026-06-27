WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT kt.kind) AS distinct_kind_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info_idx mi ON mi.movie_id = t.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    name,
    movie_count,
    character_count,
    distinct_kind_count,
    distinct_company_count,
    distinct_info_type_count,
    first_year,
    last_year
FROM actor_stats
WHERE movie_count >= 5
ORDER BY movie_count DESC, character_count DESC
LIMIT 100
