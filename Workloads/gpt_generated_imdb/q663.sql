WITH movie_cast_counts AS (
  SELECT ci.movie_id,
         COUNT(DISTINCT ci.person_id) AS cast_count
  FROM cast_info ci
  GROUP BY ci.movie_id
),
movie_company_types AS (
  SELECT DISTINCT mc.movie_id,
         ct.kind AS company_type_kind
  FROM movie_companies mc
  JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT
  t.production_year,
  mct.company_type_kind,
  COUNT(DISTINCT t.id) AS movie_count,
  AVG(mcc.cast_count) AS avg_cast_per_movie
FROM title t
JOIN movie_company_types mct ON mct.movie_id = t.id
JOIN movie_cast_counts mcc ON mcc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, mct.company_type_kind
ORDER BY t.production_year DESC, movie_count DESC
LIMIT 20
