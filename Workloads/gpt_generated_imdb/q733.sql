WITH rating_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
budget_info AS (
    SELECT mi_idx.movie_id,
           CAST(mi_idx.info AS double) AS budget
    FROM movie_info_idx mi_idx
    JOIN info_type it ON mi_idx.info_type_id = it.id
    WHERE it.info = 'budget'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT t.title,
       kt.kind,
       COALESCE(cc.cast_cnt, 0) AS cast_count,
       COALESCE(comp.company_cnt, 0) AS company_count,
       AVG(r.rating) AS avg_rating,
       SUM(b.budget) AS total_budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts comp ON comp.movie_id = t.id
LEFT JOIN rating_info r ON r.movie_id = t.id
LEFT JOIN budget_info b ON b.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.title, kt.kind, cc.cast_cnt, comp.company_cnt
ORDER BY avg_rating DESC NULLS LAST, cast_count DESC
LIMIT 10
