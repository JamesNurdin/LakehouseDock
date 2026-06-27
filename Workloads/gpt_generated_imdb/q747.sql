WITH movie_stats AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type_info,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        AVG(mi_idx.note) AS avg_note_idx
    FROM info_type it
    JOIN movie_info mi
        ON mi.info_type_id = it.id
    JOIN title t
        ON mi.movie_id = t.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = t.id
        AND mi_idx.info_type_id = it.id
    GROUP BY it.id, it.info
),
person_stats AS (
    SELECT
        it.id AS info_type_id,
        COUNT(DISTINCT pi.person_id) AS person_count
    FROM info_type it
    JOIN person_info pi
        ON pi.info_type_id = it.id
    GROUP BY it.id
)
SELECT
    ms.info_type_info,
    ms.movie_count,
    ms.avg_production_year,
    ms.avg_note_idx,
    ps.person_count
FROM movie_stats ms
LEFT JOIN person_stats ps
    ON ms.info_type_id = ps.info_type_id
ORDER BY ms.movie_count DESC
LIMIT 20
