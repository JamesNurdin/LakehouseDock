WITH movie_genres AS (
    SELECT
        mi.movie_id,
        it.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(*) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    mg.genre,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mcc.cast_count) AS avg_cast_per_movie
FROM movie_genres mg
JOIN title t ON mg.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
GROUP BY mg.genre, kt.kind
ORDER BY movie_count DESC
LIMIT 20
