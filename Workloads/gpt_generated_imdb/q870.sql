WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        COUNT(DISTINCT ci.person_role_id) AS distinct_roles_count,
        COUNT(DISTINCT ak.id) AS alternate_names_count,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN aka_name ak ON ak.person_id = n.id
    LEFT JOIN title t ON ci.movie_id = t.id
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie' OR kt.kind IS NULL
    GROUP BY n.id, n.name
    HAVING COUNT(DISTINCT ci.movie_id) > 0
)
SELECT
    person_id,
    person_name,
    movies_count,
    distinct_roles_count,
    alternate_names_count,
    distinct_keywords_count
FROM actor_stats
ORDER BY movies_count DESC
LIMIT 100
