WITH cast_counts AS (
   SELECT ci.movie_id,
          COUNT(DISTINCT ci.person_id) AS cast_count
   FROM cast_info ci
   GROUP BY ci.movie_id
),
company_counts AS (
   SELECT mc.movie_id,
          COUNT(DISTINCT mc.company_id) AS company_count,
          COUNT(DISTINCT ct.kind) AS company_type_count
   FROM movie_companies mc
   LEFT JOIN company_type ct ON mc.company_type_id = ct.id
   GROUP BY mc.movie_id
),
keyword_counts AS (
   SELECT mk.movie_id,
          COUNT(DISTINCT mk.keyword_id) AS keyword_count
   FROM movie_keyword mk
   GROUP BY mk.movie_id
),
info_counts AS (
   SELECT mi.movie_id,
          COUNT(DISTINCT mi.id) AS info_count
   FROM movie_info mi
   GROUP BY mi.movie_id
),
base_movies AS (
   SELECT t.id AS movie_id,
          t.title,
          t.production_year,
          kt.kind
   FROM title t
   LEFT JOIN kind_type kt ON t.kind_id = kt.id
   WHERE t.production_year >= 2000
)
SELECT
   bm.movie_id,
   bm.title,
   bm.production_year,
   bm.kind,
   COALESCE(cc.cast_count, 0) AS cast_count,
   COALESCE(compc.company_count, 0) AS company_count,
   COALESCE(compc.company_type_count, 0) AS company_type_count,
   COALESCE(kc.keyword_count, 0) AS keyword_count,
   COALESCE(ic.info_count, 0) AS info_count,
   RANK() OVER (
       ORDER BY (
           COALESCE(cc.cast_count, 0) +
           COALESCE(compc.company_count, 0) +
           COALESCE(kc.keyword_count, 0) +
           COALESCE(ic.info_count, 0)
       ) DESC
   ) AS overall_rank
FROM base_movies bm
LEFT JOIN cast_counts cc ON cc.movie_id = bm.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = bm.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = bm.movie_id
LEFT JOIN info_counts ic ON ic.movie_id = bm.movie_id
ORDER BY overall_rank
LIMIT 20
