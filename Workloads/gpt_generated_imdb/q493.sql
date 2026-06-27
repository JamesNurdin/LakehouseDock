WITH
  cast_counts AS (
    SELECT
      t.id AS movie_id,
      COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM title t
    LEFT JOIN cast_info ci
      ON ci.movie_id = t.id
    GROUP BY t.id
  ),
  keyword_counts AS (
    SELECT
      t.id AS movie_id,
      COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM title t
    LEFT JOIN movie_keyword mk
      ON mk.movie_id = t.id
    GROUP BY t.id
  ),
  company_counts AS (
    SELECT
      t.id AS movie_id,
      COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM title t
    LEFT JOIN movie_companies mc
      ON mc.movie_id = t.id
    GROUP BY t.id
  ),
  per_movie_stats AS (
    SELECT
      t.id AS movie_id,
      t.title,
      t.production_year,
      k.kind,
      COALESCE(cc.cast_cnt, 0) AS cast_cnt,
      COALESCE(kc.keyword_cnt, 0) AS keyword_cnt,
      COALESCE(compc.company_cnt, 0) AS company_cnt
    FROM title t
    LEFT JOIN kind_type k
      ON t.kind_id = k.id
    LEFT JOIN cast_counts cc
      ON cc.movie_id = t.id
    LEFT JOIN keyword_counts kc
      ON kc.movie_id = t.id
    LEFT JOIN company_counts compc
      ON compc.movie_id = t.id
  )
SELECT
  kind,
  production_year,
  COUNT(*) AS movie_cnt,
  AVG(cast_cnt) AS avg_cast_per_movie,
  AVG(keyword_cnt) AS avg_keyword_per_movie,
  AVG(company_cnt) AS avg_company_per_movie
FROM per_movie_stats
GROUP BY kind, production_year
ORDER BY movie_cnt DESC
LIMIT 20
