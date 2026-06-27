WITH stats AS (
    SELECT
        n.gender,
        pi.info_type_id,
        COUNT(DISTINCT n.id) AS distinct_persons,
        COUNT(*) AS total_info_records,
        AVG(LENGTH(pi.info)) AS avg_info_length
    FROM name n
    JOIN person_info pi ON pi.person_id = n.id
    WHERE n.gender IS NOT NULL
    GROUP BY n.gender, pi.info_type_id
)
SELECT
    gender,
    info_type_id,
    distinct_persons,
    total_info_records,
    avg_info_length,
    RANK() OVER (PARTITION BY gender ORDER BY distinct_persons DESC) AS rank_by_gender
FROM stats
ORDER BY gender, rank_by_gender
