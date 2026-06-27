WITH rating_per_movie AS (
    SELECT mi.movie_id,
           TRY_CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    k.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count,
    AVG(r.rating) AS avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN rating_per_movie r ON r.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY k.keyword
ORDER BY movie_count DESC
LIMIT 10
