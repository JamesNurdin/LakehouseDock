WITH rating_movies AS (
    SELECT mi.movie_id,
           mi.note AS rating
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    GROUP BY mc.movie_id
)
SELECT t.production_year,
       COUNT(DISTINCT rm.movie_id) AS movie_cnt,
       AVG(rm.rating) AS avg_rating,
       AVG(cc.company_cnt) AS avg_companies
FROM title t
JOIN rating_movies rm ON rm.movie_id = t.id
JOIN company_counts cc ON cc.movie_id = t.id
WHERE t.kind_id = 1
  AND cc.company_cnt >= 2
GROUP BY t.production_year
ORDER BY AVG(rm.rating) DESC
LIMIT 5
