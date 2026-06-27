WITH movie_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    COUNT(*) AS movie_count
  FROM title
  JOIN kind_type
    ON title.kind_id = kind_type.id
  GROUP BY title.production_year, kind_type.kind
),
cast_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    COUNT(DISTINCT cast_info.person_id) AS cast_count
  FROM title
  JOIN kind_type
    ON title.kind_id = kind_type.id
  JOIN cast_info
    ON cast_info.movie_id = title.id
  GROUP BY title.production_year, kind_type.kind
),
company_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    COUNT(DISTINCT movie_companies.company_id) AS company_count
  FROM title
  JOIN kind_type
    ON title.kind_id = kind_type.id
  JOIN movie_companies
    ON movie_companies.movie_id = title.id
  GROUP BY title.production_year, kind_type.kind
),
keyword_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
  FROM title
  JOIN kind_type
    ON title.kind_id = kind_type.id
  JOIN movie_keyword
    ON movie_keyword.movie_id = title.id
  GROUP BY title.production_year, kind_type.kind
),
genre_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    movie_info.info AS genre,
    COUNT(DISTINCT title.id) AS title_count
  FROM title
  JOIN kind_type
    ON title.kind_id = kind_type.id
  JOIN movie_info
    ON movie_info.movie_id = title.id
  JOIN info_type
    ON movie_info.info_type_id = info_type.id
  WHERE info_type.info = 'genre'
  GROUP BY title.production_year, kind_type.kind, movie_info.info
),
top_genre AS (
  SELECT
    production_year,
    kind,
    genre,
    title_count
  FROM (
    SELECT
      production_year,
      kind,
      genre,
      title_count,
      ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY title_count DESC) AS rn
    FROM genre_counts
  ) sub
  WHERE rn = 1
)
SELECT
  mc.production_year,
  mc.kind,
  mc.movie_count,
  COALESCE(cc.cast_count, 0) AS cast_count,
  COALESCE(compc.company_count, 0) AS company_count,
  COALESCE(kc.keyword_count, 0) AS keyword_count,
  tg.genre AS top_genre,
  tg.title_count AS top_genre_movie_count
FROM movie_counts mc
LEFT JOIN cast_counts cc
  ON mc.production_year = cc.production_year AND mc.kind = cc.kind
LEFT JOIN company_counts compc
  ON mc.production_year = compc.production_year AND mc.kind = compc.kind
LEFT JOIN keyword_counts kc
  ON mc.production_year = kc.production_year AND mc.kind = kc.kind
LEFT JOIN top_genre tg
  ON mc.production_year = tg.production_year AND mc.kind = tg.kind
ORDER BY mc.production_year, mc.kind
