/* Top 10 genres (by number of movies released from 2010 onward) with average cast size */
WITH genre_movies AS (
    SELECT
        ti.id AS movie_id,
        mi.info AS genre,
        ti.production_year
    FROM title ti
    JOIN movie_info mi ON mi.movie_id = ti.id
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
      AND ti.production_year >= 2010
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    gm.genre,
    COUNT(DISTINCT gm.movie_id) AS total_movies,
    AVG(cc.num_cast) AS avg_cast_per_movie
FROM genre_movies gm
JOIN cast_counts cc ON cc.movie_id = gm.movie_id
GROUP BY gm.genre
ORDER BY total_movies DESC
LIMIT 10
