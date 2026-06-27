WITH movie_stats AS (
    SELECT
        ti.production_year,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        COUNT(DISTINCT mi.id) AS movie_info_entries,
        AVG(mi_idx.note) AS avg_idx_note
    FROM movie_info mi
    JOIN title ti
        ON mi.movie_id = ti.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = ti.id
        AND mi_idx.info_type_id = it.id
    GROUP BY ti.production_year, it.info
),
person_stats AS (
    SELECT
        it.info AS info_type,
        COUNT(DISTINCT pi.person_id) AS person_count,
        COUNT(DISTINCT pi.id) AS person_info_entries,
        COUNT(DISTINCT aka.name) AS distinct_aka_names
    FROM person_info pi
    JOIN name n
        ON pi.person_id = n.id
    JOIN info_type it
        ON pi.info_type_id = it.id
    LEFT JOIN aka_name aka
        ON aka.person_id = n.id
    GROUP BY it.info
)
SELECT
    ms.production_year,
    ms.info_type,
    ms.movie_count,
    ms.movie_info_entries,
    ms.avg_idx_note,
    ps.person_count,
    ps.person_info_entries,
    ps.distinct_aka_names
FROM movie_stats ms
JOIN person_stats ps
    ON ms.info_type = ps.info_type
WHERE ms.movie_count >= 5
ORDER BY ms.production_year, ms.movie_count DESC
