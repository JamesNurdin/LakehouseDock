/*
  Analytical query: for each production year and title kind (e.g., movie, TV series),
  count the number of titles and compute the average number of cast members,
  keywords, and production companies per title.
*/
WITH cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_base AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt
      ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
)
SELECT mb.production_year,
       mb.kind,
       COUNT(*) AS movies,
       AVG(COALESCE(ca.cast_count, 0)) AS avg_cast_per_movie,
       AVG(COALESCE(ka.keyword_count, 0)) AS avg_keywords_per_movie,
       AVG(COALESCE(coa.company_count, 0)) AS avg_companies_per_movie
FROM movie_base mb
LEFT JOIN cast_agg ca   ON ca.movie_id   = mb.movie_id
LEFT JOIN keyword_agg ka ON ka.movie_id   = mb.movie_id
LEFT JOIN company_agg coa ON coa.movie_id = mb.movie_id
GROUP BY mb.production_year, mb.kind
ORDER BY mb.production_year DESC, movies DESC
LIMIT 20
