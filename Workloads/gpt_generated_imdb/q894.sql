WITH movie_kw AS (
    SELECT mk.keyword_id AS keyword_id,
           t.id AS movie_id,
           t.production_year AS production_year
    FROM movie_keyword mk
    JOIN title t
      ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
),
keyword_stats AS (
    SELECT kw.keyword_id AS keyword_id,
           COUNT(DISTINCT kw.movie_id) AS movie_count,
           AVG(kw.production_year) AS avg_production_year,
           MIN(kw.production_year) AS earliest_year,
           MAX(kw.production_year) AS latest_year
    FROM movie_kw kw
    GROUP BY kw.keyword_id
)
SELECT k.id,
       k.keyword,
       ks.movie_count,
       ks.avg_production_year,
       ks.earliest_year,
       ks.latest_year
FROM keyword_stats ks
JOIN keyword k
  ON ks.keyword_id = k.id
ORDER BY ks.movie_count DESC
LIMIT 10
