WITH info_counts AS (
    SELECT
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count_mi,
        COUNT(DISTINCT mi.id) AS movie_info_entries,
        COUNT(DISTINCT mi_idx.movie_id) AS movie_count_mi_idx,
        COUNT(DISTINCT mi_idx.id) AS movie_info_idx_entries,
        AVG(mi_idx.note) AS avg_note_mi_idx,
        COUNT(DISTINCT pi.person_id) AS person_count_pi,
        COUNT(DISTINCT pi.id) AS person_info_entries,
        COUNT(DISTINCT ak.id) AS aka_name_count
    FROM info_type it
    LEFT JOIN movie_info mi
        ON mi.info_type_id = it.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.info_type_id = it.id
    LEFT JOIN person_info pi
        ON pi.info_type_id = it.id
    LEFT JOIN name n
        ON n.id = pi.person_id
    LEFT JOIN aka_name ak
        ON ak.person_id = n.id
    GROUP BY it.info
)
SELECT
    info_type,
    movie_count_mi,
    movie_info_entries,
    movie_count_mi_idx,
    movie_info_idx_entries,
    avg_note_mi_idx,
    person_count_pi,
    person_info_entries,
    aka_name_count
FROM info_counts
ORDER BY movie_count_mi DESC, person_count_pi DESC
LIMIT 10
