WITH
    movies AS (
        SELECT
            t.id,
            t.production_year,
            t.kind_id
        FROM title t
    ),
    kinds AS (
        SELECT
            kt.id,
            kt.kind
        FROM kind_type kt
    ),
    cast_counts AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_cnt
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    keyword_counts AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    info_counts AS (
        SELECT
            mi.movie_id,
            COUNT(DISTINCT mi.info_type_id) AS info_type_cnt
        FROM movie_info mi
        GROUP BY mi.movie_id
    )
SELECT
    m.production_year,
    k.kind,
    COUNT(m.id) AS movie_cnt,
    SUM(COALESCE(cc.cast_cnt, 0)) AS total_cast_members,
    SUM(COALESCE(compc.company_cnt, 0)) AS total_companies,
    SUM(COALESCE(kc.keyword_cnt, 0)) AS total_keywords,
    SUM(COALESCE(ic.info_type_cnt, 0)) AS total_info_types
FROM movies m
JOIN kinds k ON m.kind_id = k.id
LEFT JOIN cast_counts cc ON m.id = cc.movie_id
LEFT JOIN company_counts compc ON m.id = compc.movie_id
LEFT JOIN keyword_counts kc ON m.id = kc.movie_id
LEFT JOIN info_counts ic ON m.id = ic.movie_id
GROUP BY m.production_year, k.kind
ORDER BY m.production_year, k.kind
