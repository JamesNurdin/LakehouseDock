WITH
  cast_counts AS (
    SELECT
      ci.movie_id,
      COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),
  rating_info AS (
    SELECT
      mi.movie_id,
      AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating' AND mi.info IS NOT NULL
    GROUP BY mi.movie_id
  ),
  production_company_counts AS (
    SELECT
      mc.movie_id,
      COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
  )
SELECT
  kt.kind AS movie_kind,
  t.production_year,
  COUNT(DISTINCT t.id) AS movie_count,
  AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_count,
  AVG(r.rating) AS avg_rating,
  AVG(COALESCE(pc.prod_company_count, 0)) AS avg_prod_company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN rating_info r ON t.id = r.movie_id
LEFT JOIN production_company_counts pc ON t.id = pc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY movie_count DESC
LIMIT 20
