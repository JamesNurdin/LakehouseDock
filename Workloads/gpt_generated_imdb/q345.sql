/*
  Analytical query: For each title kind (e.g., movie, short, tvSeries), compute
  - total number of titles
  - average number of distinct cast members per title
  - average number of distinct production companies per title
  - average number of distinct keywords per title
  - the most common production year for that kind

  Joins are limited to the allowed relationships.
*/
WITH
  -- Count distinct cast members per movie
  cast_counts AS (
    SELECT
      ci.movie_id,
      COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),

  -- Count distinct production companies per movie
  company_counts AS (
    SELECT
      mc.movie_id,
      COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
  ),

  -- Count distinct keywords per movie
  keyword_counts AS (
    SELECT
      mk.movie_id,
      COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
  ),

  -- Combine title information with the per‑movie counts
  title_with_counts AS (
    SELECT
      t.id AS title_id,
      t.title,
      t.kind_id,
      t.production_year,
      kt.kind,
      COALESCE(cc.cast_cnt, 0) AS cast_cnt,
      COALESCE(compc.company_cnt, 0) AS company_cnt,
      COALESCE(kc.keyword_cnt, 0) AS keyword_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc   ON t.id = cc.movie_id   -- cast_info.movie_id = title.id
    LEFT JOIN company_counts compc ON t.id = compc.movie_id   -- movie_companies.movie_id = title.id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id   -- movie_keyword.movie_id = title.id
  ),

  -- Aggregate the per‑title metrics to the title kind level
  kind_aggregates AS (
    SELECT
      kind,
      COUNT(*) AS total_titles,
      AVG(cast_cnt) AS avg_cast_per_title,
      AVG(company_cnt) AS avg_companies_per_title,
      AVG(keyword_cnt) AS avg_keywords_per_title
    FROM title_with_counts
    GROUP BY kind
  ),

  -- Determine the most common production year for each kind
  year_counts AS (
    SELECT
      kt.kind,
      t.production_year,
      COUNT(*) AS year_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY kt.kind, t.production_year
  ),

  year_mode AS (
    SELECT
      kind,
      production_year,
      ROW_NUMBER() OVER (PARTITION BY kind ORDER BY year_cnt DESC) AS rn
    FROM year_counts
  )

SELECT
  ka.kind,
  ka.total_titles,
  ka.avg_cast_per_title,
  ka.avg_companies_per_title,
  ka.avg_keywords_per_title,
  ym.production_year AS most_common_production_year
FROM kind_aggregates ka
JOIN (
  SELECT kind, production_year
  FROM year_mode
  WHERE rn = 1
) ym ON ka.kind = ym.kind
ORDER BY ka.total_titles DESC
