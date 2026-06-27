WITH info_counts AS (
    SELECT
        n.gender,
        it.info AS info_type,
        COUNT(pi.id) AS total_entries,
        COUNT(DISTINCT pi.person_id) AS distinct_persons,
        AVG(LENGTH(pi.info)) AS avg_info_length
    FROM person_info pi
    JOIN name n ON pi.person_id = n.id
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE n.gender IS NOT NULL
    GROUP BY n.gender, it.info
)
SELECT
    gender,
    info_type,
    distinct_persons,
    total_entries,
    avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_entries DESC) AS rank_by_entries
FROM info_counts
ORDER BY gender, rank_by_entries
