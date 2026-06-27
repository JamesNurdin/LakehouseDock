WITH
    cast_counts AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    keyword_counts AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    runtime_flags AS (
        SELECT
            mi.movie_id,
            CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS has_runtime
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'runtime'
        GROUP BY mi.movie_id
    )
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS title_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_title,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_title,
    SUM(COALESCE(rf.has_runtime, 0)) AS titles_with_runtime
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN runtime_flags rf ON t.id = rf.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
