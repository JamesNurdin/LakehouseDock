WITH
  movie_ratings AS (
    SELECT
      mi.movie_id,
      CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
  ),
  movie_keywords AS (
    SELECT
      mk.movie_id,
      COUNT(DISTINCT k.keyword) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
  ),
  actor_movies AS (
    SELECT
      ci.person_id AS actor_id,
      ci.movie_id
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year >= 2005
  )
SELECT
  n.id AS actor_id,
  n.name AS actor_name,
  COUNT(DISTINCT am.movie_id) AS movie_count,
  AVG(r.rating) AS avg_rating,
  SUM(COALESCE(k.keyword_cnt, 0)) AS total_distinct_keywords
FROM actor_movies am
JOIN "name" n ON am.actor_id = n.id
LEFT JOIN movie_ratings r ON am.movie_id = r.movie_id
LEFT JOIN movie_keywords k ON am.movie_id = k.movie_id
GROUP BY n.id, n.name
ORDER BY movie_count DESC
LIMIT 10
