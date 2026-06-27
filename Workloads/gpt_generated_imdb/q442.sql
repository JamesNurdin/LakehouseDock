WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_per_movie
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company AS (
    SELECT mc.movie_id,
           ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT mc.company_type,
       t.production_year,
       COUNT(DISTINCT t.id) AS movie_count,
       COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
       AVG(cc.cast_per_movie) AS avg_cast_per_movie
FROM movie_company mc
JOIN title t ON mc.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN cast_counts cc ON cc.movie_id = t.id
JOIN cast_info ci ON ci.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY mc.company_type, t.production_year
ORDER BY movie_count DESC
LIMIT 20
