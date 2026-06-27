WITH cast_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
budget_info AS (
    SELECT mi.movie_id,
           TRY_CAST(mi.info AS DOUBLE) AS budget
    FROM movie_info mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
rating_info AS (
    SELECT mi_idx.movie_id,
           TRY_CAST(mi_idx.info AS DOUBLE) AS rating
    FROM movie_info_idx mi_idx
    JOIN info_type it
      ON mi_idx.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT t.production_year,
       COUNT(DISTINCT t.id) AS movie_count,
       SUM(cc.cast_count) AS total_cast,
       AVG(cc.cast_count) AS avg_cast,
       SUM(compc.company_count) AS total_companies,
       AVG(compc.company_count) AS avg_companies,
       SUM(b.budget) AS total_budget,
       AVG(b.budget) AS avg_budget,
       AVG(r.rating) AS avg_rating
FROM title t
LEFT JOIN cast_counts cc
  ON t.id = cc.movie_id
LEFT JOIN company_counts compc
  ON t.id = compc.movie_id
LEFT JOIN budget_info b
  ON t.id = b.movie_id
LEFT JOIN rating_info r
  ON t.id = r.movie_id
WHERE t.kind_id = 1
  AND t.production_year IS NOT NULL
GROUP BY t.production_year
ORDER BY t.production_year ASC
