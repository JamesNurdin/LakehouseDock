WITH
  cast_counts AS (
    SELECT
      ci.movie_id AS movie_id,
      COUNT(DISTINCT ci.person_id) AS distinct_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),
  company_counts AS (
    SELECT
      mc.movie_id AS movie_id,
      COUNT(DISTINCT cn.id) AS distinct_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
  ),
  keyword_counts AS (
    SELECT
      mk.movie_id AS movie_id,
      COUNT(DISTINCT k.id) AS distinct_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
  )
SELECT
  t.production_year,
  kt.kind AS kind,
  COUNT(DISTINCT t.id) AS distinct_movies,
  SUM(COALESCE(cc.distinct_cast, 0)) AS total_distinct_cast,
  SUM(COALESCE(compc.distinct_companies, 0)) AS total_distinct_companies,
  SUM(COALESCE(kc.distinct_keywords, 0)) AS total_distinct_keywords,
  AVG(COALESCE(cc.distinct_cast, 0)) AS avg_distinct_cast_per_movie,
  AVG(COALESCE(compc.distinct_companies, 0)) AS avg_distinct_companies_per_movie,
  AVG(COALESCE(kc.distinct_keywords, 0)) AS avg_distinct_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY total_distinct_cast DESC
LIMIT 20
