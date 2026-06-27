WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT mi.info AS genre,
       COUNT(DISTINCT t.id) AS num_movies,
       AVG(mc.cast_count) AS avg_cast_per_movie,
       AVG(t.production_year) AS avg_production_year
FROM title t
JOIN movie_info mi ON mi.movie_id = t.id
JOIN info_type it ON mi.info_type_id = it.id
JOIN movie_cast_counts mc ON mc.movie_id = t.id
WHERE it.info = 'genre'
GROUP BY mi.info
ORDER BY num_movies DESC
LIMIT 20
