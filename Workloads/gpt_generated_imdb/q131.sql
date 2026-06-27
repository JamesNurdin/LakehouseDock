WITH cast_counts AS (
    SELECT t.id AS title_id,
           COUNT(DISTINCT ci.person_id) AS num_cast
    FROM cast_info ci
    JOIN title t
      ON ci.movie_id = t.id
    GROUP BY t.id
),
company_counts AS (
    SELECT t.id AS title_id,
           COUNT(DISTINCT mc.company_id) AS num_companies
    FROM movie_companies mc
    JOIN title t
      ON mc.movie_id = t.id
    GROUP BY t.id
),
keyword_counts AS (
    SELECT t.id AS title_id,
           COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM movie_keyword mk
    JOIN title t
      ON mk.movie_id = t.id
    GROUP BY t.id
),
rating_info AS (
    SELECT t.id AS title_id,
           AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN title t
      ON mi.movie_id = t.id
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY t.id
)
SELECT t.title,
       t.production_year,
       kt.kind AS kind,
       COALESCE(cc.num_cast, 0)      AS num_cast,
       COALESCE(co.num_companies, 0) AS num_companies,
       COALESCE(kw.num_keywords, 0) AS num_keywords,
       r.avg_rating
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
  ON t.id = cc.title_id
LEFT JOIN company_counts co
  ON t.id = co.title_id
LEFT JOIN keyword_counts kw
  ON t.id = kw.title_id
LEFT JOIN rating_info r
  ON t.id = r.title_id
WHERE kt.kind = 'movie'
ORDER BY num_cast DESC
LIMIT 10
