WITH movie_stats AS (
    SELECT
        t.production_year,
        it.info AS info_type,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT mi.info) AS distinct_info_count,
        AVG(mii.note) AS avg_idx_note
    FROM title t
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON it.id = mi.info_type_id
    LEFT JOIN movie_info_idx mii
        ON mii.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND it.info IS NOT NULL
    GROUP BY t.production_year, it.info
)
SELECT
    production_year,
    info_type,
    movie_count,
    distinct_info_count,
    avg_idx_note,
    RANK() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_by_movie_count
FROM movie_stats
ORDER BY production_year DESC, rank_by_movie_count
LIMIT 50
