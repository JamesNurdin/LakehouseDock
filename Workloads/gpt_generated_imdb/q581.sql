WITH
    cast_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT person_id) AS cast_cnt
        FROM cast_info
        GROUP BY movie_id
    ),
    company_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT company_id) AS comp_cnt
        FROM movie_companies
        GROUP BY movie_id
    ),
    keyword_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT keyword_id) AS kw_cnt
        FROM movie_keyword
        GROUP BY movie_id
    ),
    info_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT info_type_id) AS info_type_cnt
        FROM movie_info_idx
        GROUP BY movie_id
    )
SELECT
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(compc.comp_cnt, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(kc.kw_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(ic.info_type_cnt, 0)) AS avg_info_types_per_movie,
    MIN(t.production_year) AS earliest_production_year,
    MAX(t.production_year) AS latest_production_year
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN info_counts ic ON ic.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY movie_count DESC
LIMIT 20
