WITH info_counts AS (
    SELECT
        it.info AS info_type,
        COUNT(*) AS total_info_entries,
        COUNT(DISTINCT mi.movie_id) AS distinct_movies,
        AVG(mi.note) AS avg_note,
        MIN(t.production_year) AS earliest_production_year,
        MAX(t.production_year) AS latest_production_year
    FROM movie_info_idx mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    JOIN title t
        ON mi.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY it.info
)
SELECT
    info_type,
    total_info_entries,
    distinct_movies,
    avg_note,
    earliest_production_year,
    latest_production_year
FROM info_counts
ORDER BY total_info_entries DESC
LIMIT 20
