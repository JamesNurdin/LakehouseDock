WITH movie_metrics AS (
    SELECT
        mi.info_type_id,
        it.info AS info_type,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(mi.note) AS avg_movie_note
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_info_idx mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY mi.info_type_id, it.info, kt.kind
),
person_metrics AS (
    SELECT
        pi.info_type_id,
        it.info AS info_type,
        n.gender,
        COUNT(DISTINCT n.id) AS person_count
    FROM name n
    JOIN person_info pi
        ON pi.person_id = n.id
    JOIN info_type it
        ON pi.info_type_id = it.id
    GROUP BY pi.info_type_id, it.info, n.gender
)
SELECT
    mm.kind,
    mm.info_type,
    mm.movie_count,
    mm.avg_movie_note,
    pm.gender,
    pm.person_count
FROM movie_metrics mm
JOIN person_metrics pm
    ON pm.info_type_id = mm.info_type_id
ORDER BY mm.movie_count DESC
LIMIT 20
