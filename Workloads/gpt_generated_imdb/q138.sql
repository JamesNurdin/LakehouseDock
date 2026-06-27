WITH yearly_counts AS (
    SELECT
        ti.production_year,
        it.info,
        COUNT(DISTINCT ti.id) AS movies_per_year,
        AVG(mi.note) AS avg_note
    FROM title ti
    JOIN movie_info_idx mi
        ON mi.movie_id = ti.id
    JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE ti.production_year IS NOT NULL
    GROUP BY ti.production_year, it.info
)
SELECT
    production_year,
    info,
    movies_per_year,
    avg_note,
    SUM(movies_per_year) OVER (PARTITION BY info ORDER BY production_year) AS cumulative_movies,
    RANK() OVER (PARTITION BY info ORDER BY movies_per_year DESC) AS rank_by_movies,
    RANK() OVER (PARTITION BY info ORDER BY avg_note DESC) AS rank_by_avg_note
FROM yearly_counts
WHERE production_year >= 2000
ORDER BY info, production_year
