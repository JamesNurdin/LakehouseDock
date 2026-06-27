WITH
  -- Number of distinct cast members per movie
  cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),

  -- Number of distinct keywords (tags) per movie
  keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
  ),

  -- Number of distinct production companies per movie
  company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
  ),

  -- Average rating per movie (rating stored as text in movie_info)
  rating_info AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
  ),

  -- Maximum budget per movie (budget stored as text in movie_info)
  budget_info AS (
    SELECT mi.movie_id,
           MAX(CAST(mi.info AS double)) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
  )
SELECT
  t.title,
  t.production_year,
  kt.kind,
  COALESCE(cc.cast_count, 0)      AS cast_count,
  COALESCE(kc.keyword_count, 0)   AS keyword_count,
  COALESCE(compc.company_count, 0) AS company_count,
  r.avg_rating,
  b.budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc      ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc   ON kc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN rating_info r       ON r.movie_id = t.id
LEFT JOIN budget_info b       ON b.movie_id = t.id
WHERE kt.kind = 'movie'
ORDER BY cast_count DESC
LIMIT 10
