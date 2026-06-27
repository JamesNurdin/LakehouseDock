WITH movie_base AS (
   SELECT t.id AS movie_id,
          t.title AS movie_title,
          t.production_year,
          kt.kind AS kind
   FROM title t
   JOIN kind_type kt ON t.kind_id = kt.id
   WHERE t.production_year >= 2000
),
cast_counts AS (
   SELECT ci.movie_id,
          COUNT(DISTINCT ci.person_id) AS cast_count
   FROM cast_info ci
   JOIN title t ON ci.movie_id = t.id
   GROUP BY ci.movie_id
),
keyword_counts AS (
   SELECT mk.movie_id,
          COUNT(DISTINCT k.id) AS keyword_count
   FROM movie_keyword mk
   JOIN title t ON mk.movie_id = t.id
   JOIN keyword k ON mk.keyword_id = k.id
   GROUP BY mk.movie_id
),
company_counts AS (
   SELECT mc.movie_id,
          COUNT(DISTINCT mc.company_id) AS company_count
   FROM movie_companies mc
   JOIN title t ON mc.movie_id = t.id
   GROUP BY mc.movie_id
)
SELECT mb.kind,
       mb.production_year,
       COUNT(*) AS total_movies,
       AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
       AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie
FROM movie_base mb
LEFT JOIN cast_counts cc     ON mb.movie_id = cc.movie_id
LEFT JOIN keyword_counts kc  ON mb.movie_id = kc.movie_id
LEFT JOIN company_counts compc ON mb.movie_id = compc.movie_id
GROUP BY mb.kind, mb.production_year
ORDER BY total_movies DESC
LIMIT 20
