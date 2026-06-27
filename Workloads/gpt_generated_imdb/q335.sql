WITH filtered_titles AS (
   SELECT 
      id,
      title,
      production_year
   FROM title
   WHERE production_year BETWEEN 2000 AND 2020
),
cast_counts AS (
   SELECT 
      ci.movie_id,
      COUNT(DISTINCT ci.person_id) AS cast_count,
      COUNT(DISTINCT ci.role_id) AS distinct_roles
   FROM cast_info ci
   GROUP BY ci.movie_id
),
company_counts AS (
   SELECT 
      mc.movie_id,
      COUNT(DISTINCT mc.company_id) AS company_count,
      COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
   FROM movie_companies mc
   GROUP BY mc.movie_id
),
keyword_counts AS (
   SELECT 
      mk.movie_id,
      COUNT(DISTINCT mk.keyword_id) AS keyword_count
   FROM movie_keyword mk
   GROUP BY mk.movie_id
),
info_counts AS (
   SELECT 
      mi.movie_id,
      COUNT(DISTINCT mi.info_type_id) AS info_type_count
   FROM movie_info mi
   GROUP BY mi.movie_id
)
SELECT 
   ft.id AS movie_id,
   ft.title,
   ft.production_year,
   COALESCE(cc.cast_count, 0) AS cast_count,
   COALESCE(cc.distinct_roles, 0) AS distinct_roles,
   COALESCE(comc.company_count, 0) AS company_count,
   COALESCE(comc.distinct_company_types, 0) AS distinct_company_types,
   COALESCE(kc.keyword_count, 0) AS keyword_count,
   COALESCE(ic.info_type_count, 0) AS info_type_count
FROM filtered_titles ft
LEFT JOIN cast_counts cc ON cc.movie_id = ft.id
LEFT JOIN company_counts comc ON comc.movie_id = ft.id
LEFT JOIN keyword_counts kc ON kc.movie_id = ft.id
LEFT JOIN info_counts ic ON ic.movie_id = ft.id
ORDER BY ft.production_year DESC, cast_count DESC
LIMIT 100
