WITH cast_counts AS (
    SELECT movie_id, COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id, COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_counts AS (
    SELECT movie_id, COUNT(DISTINCT info_type_id) AS info_type_count
    FROM movie_info
    GROUP BY movie_id
),
company_type_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN mc.company_id END) AS distribution_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind AS movie_kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(ic.info_type_count, 0)) AS avg_info_types_per_movie,
    AVG(COALESCE(ctc.production_company_count, 0)) AS avg_production_companies_per_movie,
    AVG(COALESCE(ctc.distribution_company_count, 0)) AS avg_distribution_companies_per_movie
FROM title t
LEFT JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN info_counts ic ON t.id = ic.movie_id
LEFT JOIN company_type_counts ctc ON t.id = ctc.movie_id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
