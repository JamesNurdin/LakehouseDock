WITH type_stats AS (
    SELECT
        it.id,
        it.info,
        COUNT(DISTINCT pi.person_id) AS distinct_persons,
        COUNT(*) AS total_entries,
        AVG(length(pi.note)) AS avg_note_length
    FROM person_info pi
    JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE pi.note IS NOT NULL
    GROUP BY it.id, it.info
    HAVING COUNT(*) > 5
)
SELECT
    id AS info_type_id,
    info AS info_type,
    distinct_persons,
    total_entries,
    avg_note_length,
    rank() OVER (ORDER BY total_entries DESC) AS entry_rank
FROM type_stats
ORDER BY total_entries DESC
LIMIT 10
