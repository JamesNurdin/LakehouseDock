WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS distinct_movie_cnt,
        COUNT(*) AS total_appearances,
        AVG(ci.person_role_id) AS avg_person_role_id
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    GROUP BY n.id, n.name, n.gender
), ranked_persons AS (
    SELECT
        person_id,
        name,
        gender,
        distinct_movie_cnt,
        total_appearances,
        avg_person_role_id,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY distinct_movie_cnt DESC) AS gender_rank
    FROM person_stats
)
SELECT
    gender,
    name,
    distinct_movie_cnt,
    total_appearances,
    avg_person_role_id,
    gender_rank
FROM ranked_persons
WHERE gender_rank <= 5
ORDER BY gender, gender_rank
