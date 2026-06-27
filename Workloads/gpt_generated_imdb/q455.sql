WITH info_stats AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(pi.id) AS total_entries,
        COUNT(DISTINCT pi.person_id) AS distinct_persons,
        AVG(LENGTH(pi.note)) AS avg_note_length,
        MAX(LENGTH(pi.note)) AS max_note_length
    FROM person_info pi
    JOIN info_type it
        ON pi.info_type_id = it.id
    WHERE pi.note IS NOT NULL
    GROUP BY it.id, it.info
    HAVING COUNT(pi.id) > 5
)
SELECT
    info_type,
    total_entries,
    distinct_persons,
    avg_note_length,
    max_note_length,
    row_number() OVER (ORDER BY distinct_persons DESC, info_type) AS rank_by_persons
FROM info_stats
ORDER BY rank_by_persons
