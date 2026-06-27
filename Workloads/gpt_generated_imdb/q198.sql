WITH
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
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    rating_info AS (
        SELECT mi.movie_id,
               AVG(CAST(mi.info AS double)) AS avg_rating
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
        GROUP BY mi.movie_id
    ),
    runtime_info AS (
        SELECT mi.movie_id,
               AVG(CAST(mi.info AS double)) AS avg_runtime
        FROM movie_info_idx mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'runtime'
        GROUP BY mi.movie_id
    )
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0)      AS cast_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(kc.keyword_count, 0)   AS keyword_count,
    r.avg_rating,
    rt.avg_runtime
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN rating_info r ON t.id = r.movie_id
LEFT JOIN runtime_info rt ON t.id = rt.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
ORDER BY r.avg_rating DESC NULLS LAST
LIMIT 10
