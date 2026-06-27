WITH movies_metrics AS (
    SELECT t.id AS movie_id,
           t.production_year,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.production_year
),
movie_genres AS (
    SELECT mi.movie_id,
           mi.info AS genre
    FROM movie_info mi
    JOIN info_type it ON it.id = mi.info_type_id
    WHERE it.info = 'genre'
)
SELECT mg.genre,
       m.production_year,
       COUNT(*) AS movie_count,
       AVG(m.cast_count) AS avg_cast_per_movie,
       AVG(m.keyword_count) AS avg_keywords_per_movie
FROM movies_metrics m
JOIN movie_genres mg ON mg.movie_id = m.movie_id
WHERE m.production_year BETWEEN 2000 AND 2020
GROUP BY mg.genre, m.production_year
ORDER BY mg.genre, m.production_year
