WITH info_aggregates AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        COUNT(DISTINCT pi.person_id) AS person_count,
        COUNT(DISTINCT mi_idx.movie_id) AS idx_movie_count,
        AVG(mi_idx.note) AS avg_idx_note
    FROM info_type it
    LEFT JOIN movie_info mi ON mi.info_type_id = it.id
    LEFT JOIN movie_info_idx mi_idx ON mi_idx.info_type_id = it.id
    LEFT JOIN person_info pi ON pi.info_type_id = it.id
    GROUP BY it.id, it.info
)
SELECT
    info_type,
    movie_count,
    person_count,
    idx_movie_count,
    avg_idx_note
FROM info_aggregates
WHERE movie_count > 0
ORDER BY movie_count DESC
LIMIT 10
