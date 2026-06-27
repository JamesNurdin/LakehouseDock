WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_size
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    k.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cc.cast_size) AS avg_cast_size,
    AVG(co.company_count) AS avg_company_count
FROM title t
JOIN kind_type kt
  ON t.kind_id = kt.id
JOIN movie_keyword mk
  ON mk.movie_id = t.id
JOIN keyword k
  ON mk.keyword_id = k.id
LEFT JOIN cast_counts cc
  ON cc.movie_id = t.id
LEFT JOIN company_counts co
  ON co.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind, k.keyword
ORDER BY t.production_year DESC, movie_count DESC
LIMIT 100
