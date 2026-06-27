WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    GROUP BY t.id, t.title, kt.kind
),
movie_ratings AS (
    SELECT
        t.id AS movie_id,
        AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM title t
    JOIN movie_info_idx mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY t.id
)
SELECT
    mc.kind,
    COUNT(*) AS num_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mr.avg_rating) AS avg_rating
FROM movie_cast_counts mc
LEFT JOIN movie_ratings mr ON mr.movie_id = mc.movie_id
GROUP BY mc.kind
ORDER BY avg_rating DESC
