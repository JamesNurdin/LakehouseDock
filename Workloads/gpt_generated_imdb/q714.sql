WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.gender,
        COUNT(DISTINCT a.id) AS aka_name_count,
        COUNT(DISTINCT p.info_type_id) AS distinct_info_type_count,
        COUNT(p.id) AS info_record_count
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    LEFT JOIN person_info p ON p.person_id = n.id
    GROUP BY n.id, n.gender
),
person_scores AS (
    SELECT
        person_id,
        gender,
        aka_name_count,
        distinct_info_type_count,
        info_record_count,
        (aka_name_count + distinct_info_type_count) AS total_score
    FROM person_stats
)
SELECT
    person_id,
    gender,
    aka_name_count,
    distinct_info_type_count,
    info_record_count,
    total_score,
    RANK() OVER (PARTITION BY gender ORDER BY total_score DESC) AS gender_rank
FROM person_scores
WHERE gender IS NOT NULL
ORDER BY gender, gender_rank
LIMIT 50
