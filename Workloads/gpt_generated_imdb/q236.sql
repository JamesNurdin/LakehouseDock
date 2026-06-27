WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
)
SELECT cn.name AS company_name,
       ct.kind AS company_type,
       kt.kind AS movie_kind,
       COUNT(DISTINCT mc.movie_id) AS movie_count,
       AVG(mcc.cast_count) AS avg_cast_per_movie
FROM movie_companies mc
JOIN company_name cn
  ON mc.company_id = cn.id
JOIN company_type ct
  ON mc.company_type_id = ct.id
JOIN title t
  ON mc.movie_id = t.id
JOIN kind_type kt
  ON t.kind_id = kt.id
JOIN movie_cast_counts mcc
  ON t.id = mcc.movie_id
WHERE t.production_year >= 2000
GROUP BY cn.name, ct.kind, kt.kind
ORDER BY movie_count DESC
LIMIT 10
