WITH role_gender_stats AS (
    SELECT
        n.gender,
        cn.name AS role_name,
        COUNT(*) AS total_appearances,
        COUNT(DISTINCT ci.movie_id) AS distinct_movies,
        COUNT(DISTINCT ci.person_id) AS distinct_persons,
        AVG(ci.nr_order) AS avg_credit_order
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE ci.nr_order IS NOT NULL
    GROUP BY n.gender, cn.name
)
SELECT
    gender,
    role_name,
    total_appearances,
    distinct_movies,
    distinct_persons,
    avg_credit_order
FROM role_gender_stats
ORDER BY total_appearances DESC
LIMIT 20
