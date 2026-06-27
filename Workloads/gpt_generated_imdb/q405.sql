WITH title_company_info AS (
    SELECT
        t.id AS title_id,
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS distinct_company_cnt,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_cnt
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY t.id, t.kind_id, t.production_year
)
SELECT
    kt.kind AS kind,
    COUNT(*) AS num_titles,
    AVG(tci.production_year) AS avg_production_year,
    SUM(tci.distinct_company_cnt) AS total_company_associations,
    SUM(tci.distinct_info_type_cnt) AS total_info_type_associations,
    AVG(tci.distinct_company_cnt) AS avg_companies_per_title,
    AVG(tci.distinct_info_type_cnt) AS avg_info_types_per_title
FROM title_company_info tci
JOIN kind_type kt ON tci.kind_id = kt.id
WHERE tci.production_year IS NOT NULL
GROUP BY kt.kind
ORDER BY num_titles DESC
