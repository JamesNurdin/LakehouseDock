WITH char_stats AS (
    SELECT
        cn.id AS char_id,
        cn.name,
        COUNT(DISTINCT ci.movie_id) AS movie_cnt,
        COUNT(*) AS appearance_cnt,
        COUNT(DISTINCT ci.person_id) AS distinct_person_cnt,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN char_name cn
        ON CAST(ci.person_role_id AS integer) = cn.id
    WHERE ci.role_id IS NOT NULL
    GROUP BY cn.id, cn.name
    HAVING COUNT(DISTINCT ci.movie_id) >= 5
)
SELECT
    cs.char_id,
    cs.name,
    cs.movie_cnt,
    cs.appearance_cnt,
    cs.distinct_person_cnt,
    cs.avg_nr_order,
    RANK() OVER (ORDER BY cs.movie_cnt DESC) AS movie_cnt_rank
FROM char_stats cs
ORDER BY cs.movie_cnt DESC
LIMIT 20
