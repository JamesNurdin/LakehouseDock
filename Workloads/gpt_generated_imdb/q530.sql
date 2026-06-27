WITH mi_counts AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year
    FROM movie_info mi
    JOIN title t ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY it.id, it.info
),
mi_idx_stats AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi_idx.movie_id) AS idx_movie_count,
        AVG(mi_idx.note) AS avg_note
    FROM movie_info_idx mi_idx
    JOIN title t ON mi_idx.movie_id = t.id
    JOIN info_type it ON mi_idx.info_type_id = it.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY it.id, it.info
)
SELECT
    COALESCE(mi.info_type, mi_idx.info_type) AS info_type,
    COALESCE(mi.movie_count, 0) AS movie_info_movie_count,
    COALESCE(mi_idx.idx_movie_count, 0) AS movie_info_idx_movie_count,
    mi_idx.avg_note,
    mi.earliest_year,
    mi.latest_year
FROM mi_counts mi
FULL OUTER JOIN mi_idx_stats mi_idx
    ON mi.info_type_id = mi_idx.info_type_id
ORDER BY movie_info_idx_movie_count DESC
LIMIT 20
