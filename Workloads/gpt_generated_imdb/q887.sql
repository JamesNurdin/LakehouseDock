WITH char_movie_stats AS (
    SELECT
        cn.id AS char_id,
        cn.name AS character_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS first_appearance_year,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name
)
SELECT
    char_id,
    character_name,
    movie_count,
    first_appearance_year,
    avg_nr_order,
    RANK() OVER (ORDER BY movie_count DESC) AS movie_count_rank
FROM char_movie_stats
ORDER BY movie_count DESC
LIMIT 10
