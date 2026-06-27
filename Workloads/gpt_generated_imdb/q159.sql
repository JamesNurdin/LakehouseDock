WITH character_stats AS (
    SELECT
        cn.name AS character_name,
        COUNT(*) AS appearance_count,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(ci.nr_order) AS avg_nr_order,
        MIN(ci.nr_order) AS min_nr_order,
        MAX(ci.nr_order) AS max_nr_order
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE ci.note IS NOT NULL
    GROUP BY cn.name
)
SELECT
    character_name,
    appearance_count,
    movie_count,
    avg_nr_order,
    min_nr_order,
    max_nr_order,
    RANK() OVER (ORDER BY appearance_count DESC) AS appearance_rank
FROM character_stats
ORDER BY appearance_count DESC
LIMIT 20
