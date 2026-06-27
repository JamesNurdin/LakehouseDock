WITH rating_per_movie AS (
  SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    ri.note AS rating
  FROM title t
  JOIN movie_info_idx ri
    ON ri.movie_id = t.id
  JOIN info_type it
    ON it.id = ri.info_type_id
  WHERE it.info = 'rating'
    AND ri.note > 0
    AND t.production_year >= 2000
),
genre_per_movie AS (
  SELECT
    t.id AS movie_id,
    it.info AS genre,
    t.production_year
  FROM title t
  JOIN movie_info gi
    ON gi.movie_id = t.id
  JOIN info_type it
    ON it.id = gi.info_type_id
  WHERE it.info = 'genre'
),
genre_counts_per_year AS (
  SELECT
    g.production_year,
    g.genre,
    COUNT(DISTINCT g.movie_id) AS genre_movie_cnt
  FROM genre_per_movie g
  GROUP BY g.production_year, g.genre
),
top_genre_per_year AS (
  SELECT
    production_year,
    genre
  FROM (
    SELECT
      production_year,
      genre,
      ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY genre_movie_cnt DESC) AS rn
    FROM genre_counts_per_year
  ) t
  WHERE rn = 1
),
rating_agg_per_year AS (
  SELECT
    r.production_year,
    COUNT(DISTINCT r.movie_id) AS movie_count,
    AVG(r.rating) AS avg_rating
  FROM rating_per_movie r
  GROUP BY r.production_year
)
SELECT
  ra.production_year,
  ra.movie_count,
  ra.avg_rating,
  tg.genre AS top_genre
FROM rating_agg_per_year ra
LEFT JOIN top_genre_per_year tg
  ON tg.production_year = ra.production_year
ORDER BY ra.production_year DESC
LIMIT 20
