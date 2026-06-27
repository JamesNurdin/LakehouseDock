WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT kt.kind AS genre,
       t.production_year,
       COUNT(DISTINCT t.id) AS total_movies,
       AVG(COALESCE(mcc.cast_count, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(mkc.keyword_count, 0)) AS avg_keywords_per_movie,
       AVG(COALESCE(mcomc.company_count, 0)) AS avg_companies_per_movie
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mcc
  ON t.id = mcc.movie_id
LEFT JOIN movie_keyword_counts mkc
  ON t.id = mkc.movie_id
LEFT JOIN movie_company_counts mcomc
  ON t.id = mcomc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY t.production_year DESC, kt.kind
