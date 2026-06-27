WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
info_counts AS (
    SELECT mi.movie_id,
           COUNT(DISTINCT mi.id) AS info_count,
           SUM(CASE WHEN it.info = 'plot' THEN 1 ELSE 0 END) AS plot_info_count
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(pc.production_company_count, 0) AS production_company_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(ic.info_count, 0) AS info_count,
    COALESCE(ic.plot_info_count, 0) AS plot_info_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts pc ON pc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN info_counts ic ON ic.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 100
