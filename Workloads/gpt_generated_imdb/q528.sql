WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.movie_id
),
genre_movies AS (
    SELECT
        mi.movie_id,
        mi.info,
        t.production_year,
        mc.cast_count
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    JOIN title t ON mi.movie_id = t.id
    JOIN movie_cast_counts mc ON t.id = mc.movie_id
    WHERE it.info = 'genres'
)
SELECT
    gm.info AS genre,
    gm.production_year,
    COUNT(DISTINCT gm.movie_id) AS movies_count,
    AVG(gm.cast_count) AS avg_cast_per_movie
FROM genre_movies gm
GROUP BY gm.info, gm.production_year
ORDER BY gm.info, gm.production_year
