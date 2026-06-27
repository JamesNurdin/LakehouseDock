WITH cast_counts AS (
  SELECT
    ci.movie_id,
    COUNT(DISTINCT ci.person_id) AS cast_cnt,
    COUNT(DISTINCT ci.person_role_id) AS char_cnt
  FROM cast_info ci
  GROUP BY ci.movie_id
),
company_counts AS (
  SELECT
    mc.movie_id,
    COUNT(DISTINCT mc.company_id) AS comp_cnt
  FROM movie_companies mc
  GROUP BY mc.movie_id
),
movie_kinds AS (
  SELECT
    t.id AS movie_id,
    t.title,
    kt.kind
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  WHERE t.production_year >= 2000
)
SELECT
  mk.kind,
  COUNT(mk.movie_id) AS movie_cnt,
  AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
  AVG(COALESCE(cc.char_cnt, 0)) AS avg_characters_per_movie,
  AVG(COALESCE(compc.comp_cnt, 0)) AS avg_companies_per_movie
FROM movie_kinds mk
LEFT JOIN cast_counts cc ON mk.movie_id = cc.movie_id
LEFT JOIN company_counts compc ON mk.movie_id = compc.movie_id
GROUP BY mk.kind
ORDER BY avg_cast_per_movie DESC
LIMIT 10
