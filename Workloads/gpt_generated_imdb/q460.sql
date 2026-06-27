WITH role_counts AS (
    SELECT
        n.gender,
        cn.name AS character_name,
        COUNT(DISTINCT ci.movie_id) AS distinct_movie_cnt,
        COUNT(*) AS total_appearances
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE n.gender IS NOT NULL
    GROUP BY n.gender, cn.name
)
SELECT
    gender,
    character_name,
    distinct_movie_cnt,
    total_appearances
FROM (
    SELECT
        gender,
        character_name,
        distinct_movie_cnt,
        total_appearances,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY distinct_movie_cnt DESC, total_appearances DESC) AS rn
    FROM role_counts
) t
WHERE rn <= 5
ORDER BY gender, rn
