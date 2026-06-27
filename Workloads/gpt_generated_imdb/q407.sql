WITH info_stats AS (
    SELECT
        n.gender,
        pi.info_type_id,
        COUNT(*) AS info_record_count,
        COUNT(DISTINCT n.id) AS distinct_person_count,
        AVG(LENGTH(pi.info)) AS avg_info_length
    FROM person_info pi
    JOIN name n
        ON pi.person_id = n.id
    WHERE n.gender IS NOT NULL
    GROUP BY n.gender, pi.info_type_id
)
SELECT
    gender,
    info_type_id,
    info_record_count,
    distinct_person_count,
    avg_info_length
FROM info_stats
ORDER BY gender, info_record_count DESC
