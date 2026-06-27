WITH char_movie_counts AS (
    SELECT
        cn.id AS char_id,
        cn.name AS character_name,
        t.production_year,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(ci.nr_order) AS total_nr_order,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE t.kind_id = 1
    GROUP BY cn.id, cn.name, t.production_year
)
SELECT
    character_name,
    production_year,
    movie_count,
    total_nr_order,
    avg_nr_order,
    RANK() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_by_movie_count
FROM char_movie_counts
ORDER BY production_year DESC, rank_by_movie_count
LIMIT 100
