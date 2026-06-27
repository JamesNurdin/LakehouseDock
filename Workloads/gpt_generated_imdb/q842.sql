WITH cast_counts AS (
    SELECT ci.movie_id,
           count(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           count(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
production_company_counts AS (
    SELECT mc.movie_id,
           count(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
runtime_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT kt.kind AS kind_name,
       count(DISTINCT t.id) AS movie_count,
       avg(coalesce(cc.cast_count, 0)) AS avg_cast_count,
       avg(coalesce(kc.keyword_count, 0)) AS avg_keyword_count,
       avg(coalesce(pc.prod_company_count, 0)) AS avg_prod_company_count,
       avg(ri.runtime_minutes) AS avg_runtime_minutes
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN production_company_counts pc ON t.id = pc.movie_id
LEFT JOIN runtime_info ri ON t.id = ri.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind
ORDER BY avg_cast_count DESC
LIMIT 10
