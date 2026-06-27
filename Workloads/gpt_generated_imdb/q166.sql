WITH rating_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
genre_info AS (
    SELECT mi.movie_id,
           mi.info AS genre
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
)
SELECT ci.person_id,
       n.name,
       COUNT(DISTINCT t.id) AS movie_count,
       AVG(r.rating) AS avg_rating,
       MIN(t.production_year) AS earliest_year,
       MAX(t.production_year) AS latest_year,
       COUNT(DISTINCT g.genre) AS genre_count
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN rating_info r ON t.id = r.movie_id
LEFT JOIN genre_info g ON t.id = g.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
GROUP BY ci.person_id, n.name
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 5
