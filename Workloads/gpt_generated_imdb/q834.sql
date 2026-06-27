/*
  Top 10 keywords (genres) with the highest average number of distinct cast members per title
  for titles released between 2000 and 2020, broken down by title kind (e.g., movie, TV series).
*/
WITH movies AS (
    SELECT t.id AS movie_id,
           t.kind_id,
           t.production_year
    FROM title t
    WHERE t.production_year BETWEEN 2000 AND 2020
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN movies m ON ci.movie_id = m.movie_id
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT mk.movie_id,
           k.keyword
    FROM movie_keyword mk
    JOIN movies m ON mk.movie_id = m.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
)
SELECT mk.keyword,
       kt.kind,
       AVG(cc.cast_count) AS avg_cast_per_movie,
       COUNT(DISTINCT mk.movie_id) AS movie_count
FROM movie_keywords mk
JOIN cast_counts cc ON mk.movie_id = cc.movie_id
JOIN movies m ON mk.movie_id = m.movie_id
JOIN kind_type kt ON m.kind_id = kt.id
GROUP BY mk.keyword, kt.kind
ORDER BY avg_cast_per_movie DESC
LIMIT 10
