WITH movie_genre AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        mi.info AS genre
    FROM title t
    JOIN movie_info_idx mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
      AND mi.info IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    mg.production_year,
    mg.genre,
    COUNT(*) AS movie_count,
    AVG(cc.cast_count) AS avg_cast_per_movie,
    SUM(cc.cast_count) AS total_cast_members
FROM movie_genre mg
LEFT JOIN cast_counts cc
    ON cc.movie_id = mg.movie_id
GROUP BY
    mg.production_year,
    mg.genre
ORDER BY
    mg.production_year DESC,
    mg.genre
