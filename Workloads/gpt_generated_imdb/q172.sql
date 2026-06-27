/*
  Analytical query: For each production year (from 2000 onward) and each movie kind,
  compute the number of movies, the average number of distinct cast members per movie,
  the average number of distinct keywords per movie, and the average number of distinct
  company types involved per movie.
*/
WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_type_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_type_id) AS comp_type_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind AS kind,
    COUNT(t.id) AS movie_cnt,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(ctc.comp_type_cnt, 0)) AS avg_company_types_per_movie
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN cast_counts cc
  ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc
  ON kc.movie_id = t.id
LEFT JOIN company_type_counts ctc
  ON ctc.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year, kt.kind
