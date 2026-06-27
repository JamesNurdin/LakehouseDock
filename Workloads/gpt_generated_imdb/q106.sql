WITH rating_per_movie AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_count_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    AVG(r.rating) AS avg_rating
FROM title t
LEFT JOIN cast_count_per_movie cc
    ON cc.movie_id = t.id
LEFT JOIN rating_per_movie r
    ON r.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY t.production_year
