WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS num_cast,
           COUNT(DISTINCT ci.person_role_id) AS num_characters
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS num_companies,
           COUNT(DISTINCT ct.kind) AS num_company_types
    FROM movie_companies mc
    JOIN company_type ct
      ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_info AS (
    SELECT mi.movie_id,
           AVG(TRY_CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       COALESCE(cc.num_cast, 0) AS num_cast,
       COALESCE(cc.num_characters, 0) AS num_characters,
       COALESCE(compc.num_companies, 0) AS num_companies,
       COALESCE(compc.num_company_types, 0) AS num_company_types,
       COALESCE(kc.num_keywords, 0) AS num_keywords,
       rating.avg_rating
FROM title t
LEFT JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
  ON t.id = cc.movie_id
LEFT JOIN company_counts compc
  ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc
  ON t.id = kc.movie_id
LEFT JOIN rating_info rating
  ON t.id = rating.movie_id
WHERE t.production_year >= 2000
ORDER BY rating.avg_rating DESC NULLS LAST
LIMIT 20
