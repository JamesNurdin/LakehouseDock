WITH rating_per_movie AS (
    SELECT
        movie_id,
        AVG(note) AS avg_rating,
        COUNT(*) AS rating_count
    FROM movie_info_idx
    GROUP BY movie_id
),
info_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS distinct_info_type_count
    FROM movie_info
    GROUP BY movie_id
)
SELECT
    CAST(t.production_year AS integer) AS production_year,
    t.kind_id,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(r.avg_rating) AS avg_movie_rating,
    AVG(i.distinct_info_type_count) AS avg_distinct_info_types
FROM title t
LEFT JOIN rating_per_movie r
    ON r.movie_id = t.id
LEFT JOIN info_counts i
    ON i.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY CAST(t.production_year AS integer), t.kind_id
ORDER BY production_year DESC, t.kind_id
