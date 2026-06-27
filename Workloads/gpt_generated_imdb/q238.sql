WITH base_titles AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_entries
    FROM movie_info mi
    GROUP BY mi.movie_id
),
info_idx_agg AS (
    SELECT
        mii.movie_id,
        COUNT(*) AS info_idx_entries
    FROM movie_info_idx mii
    GROUP BY mii.movie_id
)
SELECT
    bt.kind,
    bt.production_year,
    COUNT(*) AS num_titles,
    AVG(COALESCE(ca.distinct_cast, 0)) AS avg_cast_per_title,
    AVG(COALESCE(coa.distinct_companies, 0)) AS avg_companies_per_title,
    AVG(COALESCE(ka.distinct_keywords, 0)) AS avg_keywords_per_title,
    AVG(COALESCE(ia.info_entries, 0)) AS avg_info_entries_per_title,
    AVG(COALESCE(iia.info_idx_entries, 0)) AS avg_info_idx_entries_per_title
FROM base_titles bt
LEFT JOIN cast_agg ca ON ca.movie_id = bt.movie_id
LEFT JOIN company_agg coa ON coa.movie_id = bt.movie_id
LEFT JOIN keyword_agg ka ON ka.movie_id = bt.movie_id
LEFT JOIN info_agg ia ON ia.movie_id = bt.movie_id
LEFT JOIN info_idx_agg iia ON iia.movie_id = bt.movie_id
GROUP BY bt.kind, bt.production_year
ORDER BY bt.kind, bt.production_year DESC
