WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND kt.kind = 'movie'
    GROUP BY t.id
)
SELECT
    cn.name AS company,
    cn.country_code AS country,
    CAST(t.production_year AS integer) AS prod_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mcc.cast_count) AS avg_cast_per_movie
FROM movie_companies mc
JOIN title t ON mc.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
WHERE kt.kind = 'movie'
  AND t.production_year BETWEEN 2000 AND 2020
  AND ct.kind = 'production'
GROUP BY cn.name, cn.country_code, CAST(t.production_year AS integer)
ORDER BY movie_count DESC
LIMIT 10
