WITH rating_per_movie AS (
    SELECT mi.movie_id,
           MAX(mi.note) AS rating
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
keyword_count_per_movie AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
genre_per_movie AS (
    SELECT mi.movie_id,
           mi.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
)
SELECT
    g.genre,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(r.rating) AS avg_rating,
    SUM(COALESCE(k.keyword_count, 0)) AS total_keywords
FROM title t
JOIN genre_per_movie g ON g.movie_id = t.id
LEFT JOIN rating_per_movie r ON r.movie_id = t.id
LEFT JOIN keyword_count_per_movie k ON k.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY g.genre
ORDER BY avg_rating DESC NULLS LAST
LIMIT 20
