WITH movie_ratings AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_keywords AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_companies_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           COUNT(DISTINCT ct.kind) AS company_type_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
movie_cast AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       COALESCE(mr.rating, 0) AS rating,
       COALESCE(mc.company_count, 0) AS company_count,
       COALESCE(mc.company_type_count, 0) AS company_type_count,
       COALESCE(mk.keyword_count, 0) AS keyword_count,
       COALESCE(mcast.cast_count, 0) AS cast_count,
       COALESCE(mcast.character_count, 0) AS character_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings mr ON mr.movie_id = t.id
LEFT JOIN movie_companies_agg mc ON mc.movie_id = t.id
LEFT JOIN movie_keywords mk ON mk.movie_id = t.id
LEFT JOIN movie_cast mcast ON mcast.movie_id = t.id
WHERE t.production_year >= 2010
  AND kt.kind = 'movie'
ORDER BY rating DESC, cast_count DESC
LIMIT 20
