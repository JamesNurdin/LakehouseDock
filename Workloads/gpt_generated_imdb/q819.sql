WITH cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT mc.company_id) AS comp_cnt,
               COUNT(DISTINCT ct.kind)      AS comp_type_cnt
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        GROUP BY mc.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS kw_cnt
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    )
SELECT
    t.production_year,
    kt.kind,
    COUNT(t.id)                                 AS movie_cnt,
    SUM(COALESCE(cc.cast_cnt, 0))               AS total_cast_members,
    AVG(COALESCE(cc.cast_cnt, 0))               AS avg_cast_per_movie,
    SUM(COALESCE(compc.comp_cnt, 0))            AS total_companies,
    AVG(COALESCE(compc.comp_cnt, 0))            AS avg_companies_per_movie,
    SUM(COALESCE(compc.comp_type_cnt, 0))       AS total_company_types,
    AVG(COALESCE(compc.comp_type_cnt, 0))       AS avg_company_types_per_movie,
    SUM(COALESCE(kc.kw_cnt, 0))                 AS total_keywords,
    AVG(COALESCE(kc.kw_cnt, 0))                 AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc   ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc   ON t.id = kc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
LIMIT 20
