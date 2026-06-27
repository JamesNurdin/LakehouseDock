WITH keyword_counts AS (
  SELECT
    k.id AS keyword_id,
    k.keyword,
    t.production_year,
    COUNT(DISTINCT mk.movie_id) AS movie_cnt
  FROM movie_keyword mk
  JOIN title t
    ON mk.movie_id = t.id
  JOIN keyword k
    ON mk.keyword_id = k.id
  WHERE t.production_year IS NOT NULL
    AND t.production_year >= 2000
  GROUP BY k.id, k.keyword, t.production_year
),
ranked_keywords AS (
  SELECT
    keyword_id,
    keyword,
    production_year,
    movie_cnt,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_cnt DESC) AS rn
  FROM keyword_counts
)
SELECT
  production_year,
  keyword,
  movie_cnt
FROM ranked_keywords
WHERE rn <= 3
ORDER BY production_year DESC, movie_cnt DESC
