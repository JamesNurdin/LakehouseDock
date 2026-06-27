WITH person_info_counts AS (
    SELECT
        pi.person_id,
        pi.info_type_id,
        COUNT(*) AS info_entries
    FROM person_info pi
    GROUP BY pi.person_id, pi.info_type_id
)
SELECT
    it.info AS info_type,
    n.gender,
    COUNT(DISTINCT n.id) AS distinct_persons,
    SUM(pic.info_entries) AS total_info_entries,
    CAST(SUM(pic.info_entries) AS double) / COUNT(DISTINCT n.id) AS avg_info_entries_per_person
FROM person_info_counts pic
JOIN name n ON pic.person_id = n.id
JOIN info_type it ON pic.info_type_id = it.id
GROUP BY it.info, n.gender
ORDER BY total_info_entries DESC
LIMIT 20
