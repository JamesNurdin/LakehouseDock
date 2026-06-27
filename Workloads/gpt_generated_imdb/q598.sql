WITH person_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(ci.role_id) AS avg_role_id,
        COUNT(DISTINCT ci.person_role_id) AS distinct_person_roles,
        MIN(ci.movie_id) AS first_movie_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    WHERE n.gender IN ('M', 'F')
    GROUP BY n.id, n.name, n.gender
    HAVING COUNT(DISTINCT ci.movie_id) >= 5
)
SELECT
    person_id,
    name,
    gender,
    movie_count,
    avg_role_id,
    distinct_person_roles,
    first_movie_id,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
FROM person_movie_stats
ORDER BY rank
LIMIT 10
