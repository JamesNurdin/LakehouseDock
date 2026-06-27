/* Top 10 movies (2000‑2020) by distinct cast size, with counts of companies, keywords and info types */
WITH cast_agg AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_agg AS (
    SELECT movie_id,
           COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_agg AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_agg AS (
    SELECT movie_id,
           COUNT(DISTINCT info_type_id) AS info_type_count
    FROM movie_info
    GROUP BY movie_id
)
SELECT t.title,
       t.production_year,
       COALESCE(ca.cast_count, 0)      AS cast_count,
       COALESCE(coa.company_count, 0) AS company_count,
       COALESCE(ka.keyword_count, 0)  AS keyword_count,
       COALESCE(ia.info_type_count, 0) AS info_type_count
FROM title t
LEFT JOIN cast_agg   ca  ON ca.movie_id   = t.id
LEFT JOIN company_agg coa ON coa.movie_id = t.id
LEFT JOIN keyword_agg ka  ON ka.movie_id  = t.id
LEFT JOIN info_agg    ia  ON ia.movie_id  = t.id
WHERE t.production_year BETWEEN 2000 AND 2020
ORDER BY cast_count DESC
LIMIT 10
