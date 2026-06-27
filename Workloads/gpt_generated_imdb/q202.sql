WITH movie_cast_stats AS (
    SELECT
        title.id AS title_id,
        title.title,
        title.production_year,
        title.kind_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        COUNT(*) AS total_cast_entries,
        AVG(cast_info.nr_order) AS avg_nr_order,
        SUM(cast_info.nr_order) AS sum_nr_order
    FROM cast_info
    JOIN title ON cast_info.movie_id = title.id
    WHERE title.production_year >= 2000
      AND title.kind_id = 1
    GROUP BY
        title.id,
        title.title,
        title.production_year,
        title.kind_id
)
SELECT
    title_id,
    title,
    production_year,
    kind_id,
    cast_count,
    total_cast_entries,
    avg_nr_order,
    sum_nr_order,
    RANK() OVER (ORDER BY cast_count DESC) AS cast_rank
FROM movie_cast_stats
ORDER BY cast_count DESC
LIMIT 10
