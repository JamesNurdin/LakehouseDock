WITH
  cast_counts AS (
    SELECT
      movie_id,
      COUNT(DISTINCT person_id) AS cast_cnt
    FROM cast_info
    GROUP BY movie_id
  ),
  company_counts AS (
    SELECT
      movie_id,
      COUNT(DISTINCT company_id) AS comp_cnt
    FROM movie_companies
    GROUP BY movie_id
  ),
  movie_budget AS (
    SELECT
      mi.movie_id,
      MAX(CAST(mi.info AS double)) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
  ),
  movie_keywords AS (
    SELECT
      mk.movie_id,
      kw.keyword
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
  ),
  movie_metrics AS (
    SELECT
      t.id AS movie_id,
      t.production_year,
      kt.kind,
      COALESCE(cc.cast_cnt, 0) AS cast_cnt,
      COALESCE(compc.comp_cnt, 0) AS comp_cnt,
      mb.budget
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN company_counts compc ON compc.movie_id = t.id
    LEFT JOIN movie_budget mb ON mb.movie_id = t.id
    WHERE t.production_year IS NOT NULL
  ),
  kind_year_agg AS (
    SELECT
      kind,
      production_year,
      COUNT(*) AS total_movies,
      AVG(cast_cnt) AS avg_cast_per_movie,
      AVG(comp_cnt) AS avg_companies_per_movie,
      AVG(budget) AS avg_budget
    FROM movie_metrics
    GROUP BY kind, production_year
  ),
  kind_year_keywords AS (
    SELECT
      kt.kind,
      t.production_year,
      COUNT(DISTINCT kw.keyword) AS distinct_keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year IS NOT NULL
    GROUP BY kt.kind, t.production_year
  )
SELECT
  agg.kind,
  agg.production_year,
  agg.total_movies,
  agg.avg_cast_per_movie,
  agg.avg_companies_per_movie,
  agg.avg_budget,
  COALESCE(kws.distinct_keyword_count, 0) AS distinct_keyword_count
FROM kind_year_agg agg
LEFT JOIN kind_year_keywords kws
  ON agg.kind = kws.kind
  AND agg.production_year = kws.production_year
ORDER BY agg.kind, agg.production_year
