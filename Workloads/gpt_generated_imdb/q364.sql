WITH rating_movies AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_cnt,
    AVG(r.rating) AS avg_rating,
    AVG(cc.cast_cnt) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN rating_movies r
  ON r.movie_id = t.id
LEFT JOIN cast_counts cc
  ON cc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY t.production_year, kt.kind
