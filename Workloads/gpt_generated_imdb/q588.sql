WITH
  movie_cast_counts AS (
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
  movie_metrics AS (
    SELECT DISTINCT
           t.production_year,
           ct.kind AS company_type_kind,
           t.id AS movie_id,
           COALESCE(mcc.cast_count, 0) AS cast_count,
           COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
    LEFT JOIN movie_keyword_counts mkc ON t.id = mkc.movie_id
    WHERE t.production_year IS NOT NULL
  ),
  movie_counts AS (
    SELECT production_year,
           company_type_kind,
           COUNT(*) AS movie_count,
           AVG(cast_count) AS avg_cast_per_movie,
           AVG(keyword_count) AS avg_keywords_per_movie
    FROM movie_metrics
    GROUP BY production_year, company_type_kind
  ),
  distinct_cast_counts AS (
    SELECT t.production_year,
           ct.kind AS company_type_kind,
           COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, ct.kind
  )
SELECT mc.production_year,
       mc.company_type_kind,
       mc.movie_count,
       mc.avg_cast_per_movie,
       mc.avg_keywords_per_movie,
       dcc.distinct_cast_count
FROM movie_counts mc
LEFT JOIN distinct_cast_counts dcc
  ON mc.production_year = dcc.production_year
  AND mc.company_type_kind = dcc.company_type_kind
ORDER BY mc.production_year DESC,
         mc.movie_count DESC
LIMIT 20
