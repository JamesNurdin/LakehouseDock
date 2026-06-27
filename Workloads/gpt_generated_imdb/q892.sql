WITH movie_ratings AS (
    SELECT mi.movie_id,
           CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_keywords AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    COUNT(*) AS total_movies,
    AVG(r.rating) AS avg_rating,
    SUM(COALESCE(k.keyword_cnt, 0)) AS total_keywords
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings r ON t.id = r.movie_id
LEFT JOIN movie_keywords k ON t.id = k.movie_id
WHERE kt.kind = 'movie'
GROUP BY t.production_year
ORDER BY t.production_year
