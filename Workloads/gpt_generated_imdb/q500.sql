WITH person_info_counts AS (
    SELECT
        pi.person_id,
        pi.info_type_id,
        COUNT(*) AS info_count,
        AVG(LENGTH(pi.info)) AS avg_info_len
    FROM person_info pi
    GROUP BY pi.person_id, pi.info_type_id
)
SELECT
    it.info AS info_type,
    COUNT(DISTINCT pic.person_id) AS distinct_persons,
    SUM(pic.info_count) AS total_info_entries,
    AVG(pic.avg_info_len) AS avg_info_length_per_person
FROM person_info_counts pic
JOIN info_type it
    ON pic.info_type_id = it.id
GROUP BY it.info
ORDER BY total_info_entries DESC
LIMIT 10
