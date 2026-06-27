WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_size
    FROM cast_info
    GROUP BY movie_id
),
rating_info AS (
    SELECT
        mi.movie_id,
        TRY_CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND TRY_CAST(mi.info AS DOUBLE) IS NOT NULL
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS title_count,
    AVG(r.rating) AS avg_rating,
    AVG(cc.cast_size) AS avg_cast_size
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN rating_info r ON r.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
