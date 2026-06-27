WITH rating_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS integer) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT t.title,
       t.production_year,
       r.rating,
       rt.runtime_minutes,
       cc.cast_count,
       co.company_count
FROM title t
LEFT JOIN rating_info r ON r.movie_id = t.id
LEFT JOIN runtime_info rt ON rt.movie_id = t.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts co ON co.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY r.rating DESC
LIMIT 10
