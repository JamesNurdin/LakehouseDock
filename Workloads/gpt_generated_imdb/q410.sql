WITH info_stats AS (
    SELECT
        it.id,
        it.info,
        COUNT(p.id) AS entry_count,
        COUNT(DISTINCT p.person_id) AS person_count,
        AVG(LENGTH(p.info)) AS avg_info_len,
        AVG(LENGTH(p.note)) AS avg_note_len
    FROM person_info p
    JOIN info_type it ON p.info_type_id = it.id
    GROUP BY it.id, it.info
)
SELECT
    id,
    info,
    entry_count,
    person_count,
    avg_info_len,
    avg_note_len,
    RANK() OVER (ORDER BY entry_count DESC) AS entry_rank
FROM info_stats
ORDER BY entry_count DESC
LIMIT 10
