WITH cast_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count,
        AVG(nr_order) AS avg_nr_order
    FROM cast_info
    GROUP BY movie_id
),
company_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_type_count
    FROM movie_info
    GROUP BY movie_id
),
info_idx_agg AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_idx_type_count
    FROM movie_info_idx
    GROUP BY movie_id
)
SELECT
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.avg_nr_order, 0) AS avg_nr_order,
    COALESCE(coa.company_count, 0) AS company_count,
    COALESCE(ka.keyword_count, 0) AS keyword_count,
    COALESCE(ia.info_type_count, 0) AS info_type_count,
    COALESCE(iia.info_idx_type_count, 0) AS info_idx_type_count
FROM title AS t
LEFT JOIN cast_agg AS ca   ON ca.movie_id = t.id
LEFT JOIN company_agg AS coa ON coa.movie_id = t.id
LEFT JOIN keyword_agg AS ka  ON ka.movie_id = t.id
LEFT JOIN info_agg AS ia    ON ia.movie_id = t.id
LEFT JOIN info_idx_agg AS iia ON iia.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 100
