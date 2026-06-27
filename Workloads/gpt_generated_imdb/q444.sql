WITH
  cast_counts AS (
    SELECT
      ci.movie_id,
      COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
  ),
  keyword_counts AS (
    SELECT
      mk.movie_id,
      COUNT(DISTINCT kw.id) AS kw_cnt
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
  ),
  company_counts AS (
    SELECT
      mc.movie_id,
      COUNT(DISTINCT cn.id) AS comp_cnt
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
  )
SELECT
  t.title AS movie_title,
  t.production_year,
  kt.kind AS genre,
  COALESCE(cc.cast_cnt, 0) AS distinct_cast_members,
  COALESCE(kc.kw_cnt, 0) AS distinct_keywords,
  COALESCE(compc.comp_cnt, 0) AS distinct_companies,
  rank() OVER (ORDER BY COALESCE(cc.cast_cnt, 0) DESC) AS cast_rank
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
WHERE t.production_year >= 2000
ORDER BY distinct_cast_members DESC
LIMIT 10
