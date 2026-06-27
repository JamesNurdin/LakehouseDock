WITH company_counts AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_cnt
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    info_counts AS (
        SELECT
            mi.movie_id,
            COUNT(DISTINCT mi.info_type_id) AS info_type_cnt
        FROM movie_info mi
        GROUP BY mi.movie_id
    )
SELECT
    kt.kind AS title_kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS title_cnt,
    AVG(cc.company_cnt) AS avg_companies_per_title,
    AVG(ic.info_type_cnt) AS avg_info_types_per_title
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN company_counts cc
    ON cc.movie_id = t.id
LEFT JOIN info_counts ic
    ON ic.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind, t.production_year
ORDER BY title_cnt DESC
LIMIT 10
