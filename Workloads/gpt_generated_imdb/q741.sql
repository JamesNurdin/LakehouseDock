WITH rating_per_movie AS (
   SELECT
     mi.movie_id,
     AVG(TRY_CAST(mi.info AS double)) AS avg_rating
   FROM movie_info mi
   JOIN info_type it ON mi.info_type_id = it.id
   WHERE it.info = 'rating'
   GROUP BY mi.movie_id
),
movie_stats AS (
   SELECT
     t.id AS movie_id,
     t.title,
     t.production_year,
     kt.kind AS kind,
     COUNT(DISTINCT ci.person_id) AS cast_count,
     COUNT(DISTINCT cn.id) AS character_count,
     COUNT(DISTINCT mk.keyword_id) AS keyword_count,
     COUNT(DISTINCT mc.company_id) AS company_count,
     r.avg_rating
   FROM title t
   JOIN kind_type kt ON t.kind_id = kt.id
   LEFT JOIN cast_info ci ON ci.movie_id = t.id
   LEFT JOIN char_name cn ON ci.person_role_id = cn.id
   LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
   LEFT JOIN movie_companies mc ON mc.movie_id = t.id
   LEFT JOIN rating_per_movie r ON r.movie_id = t.id
   WHERE t.production_year >= 2000
   GROUP BY t.id, t.title, t.production_year, kt.kind, r.avg_rating
)
SELECT
   title,
   production_year,
   kind,
   cast_count,
   character_count,
   keyword_count,
   company_count,
   avg_rating
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 10
