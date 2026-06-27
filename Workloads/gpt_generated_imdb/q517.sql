WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count,
        ARRAY_JOIN(ARRAY_AGG(DISTINCT cn.name), ', ') AS company_names,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT *
FROM movie_stats
ORDER BY distinct_cast_count DESC, distinct_company_count DESC
LIMIT 20
