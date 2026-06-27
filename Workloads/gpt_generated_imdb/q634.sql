WITH movie_ratings AS (
    SELECT mi.movie_id,
           CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
           COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
movie_production_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT cn.id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       mr.rating,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(cc.male_cast, 0) AS male_cast,
       COALESCE(cc.female_cast, 0) AS female_cast,
       COALESCE(pc.production_company_count, 0) AS production_company_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings mr ON t.id = mr.movie_id
LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
LEFT JOIN movie_production_company_counts pc ON t.id = pc.movie_id
LEFT JOIN movie_keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year >= 2000
  AND kt.kind = 'movie'
ORDER BY mr.rating DESC NULLS LAST, cast_count DESC
LIMIT 10
