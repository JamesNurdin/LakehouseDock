WITH movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_entries,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_types,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    t.kind_id,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_cnt,
    SUM(miag.info_entries) AS total_info_entries,
    AVG(miag.info_entries) AS avg_info_per_movie,
    SUM(miag.distinct_info_types) AS total_distinct_info_types,
    AVG(miag.avg_info_length) AS avg_info_length_per_movie
FROM title t
JOIN movie_info_agg miag
    ON miag.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.kind_id, t.production_year
ORDER BY avg_info_per_movie DESC
LIMIT 10
