WITH person_movie_counts AS (
    SELECT
        ci.person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_cnt,
        COUNT(*) AS cast_entries,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    WHERE ci.role_id IS NOT NULL
    GROUP BY ci.person_id, n.name, n.gender
)
SELECT
    name,
    gender,
    movie_cnt,
    cast_entries,
    avg_nr_order
FROM person_movie_counts
ORDER BY movie_cnt DESC, cast_entries DESC
LIMIT 10
