WITH titles AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        k.kind
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id AS title_id,
        COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    t.kind,
    COUNT(DISTINCT t.title_id) AS total_titles,
    COALESCE(SUM(cc.cast_cnt), 0) AS total_cast_members,
    COALESCE(SUM(kc.kw_cnt), 0) AS total_keywords,
    COALESCE(SUM(compc.comp_cnt), 0) AS total_companies,
    CASE WHEN COUNT(DISTINCT t.title_id) = 0 THEN 0
         ELSE CAST(COALESCE(SUM(cc.cast_cnt), 0) AS double) / COUNT(DISTINCT t.title_id)
    END AS avg_cast_per_title,
    CASE WHEN COUNT(DISTINCT t.title_id) = 0 THEN 0
         ELSE CAST(COALESCE(SUM(kc.kw_cnt), 0) AS double) / COUNT(DISTINCT t.title_id)
    END AS avg_keywords_per_title,
    CASE WHEN COUNT(DISTINCT t.title_id) = 0 THEN 0
         ELSE CAST(COALESCE(SUM(compc.comp_cnt), 0) AS double) / COUNT(DISTINCT t.title_id)
    END AS avg_companies_per_title
FROM titles t
LEFT JOIN cast_counts cc ON cc.title_id = t.title_id
LEFT JOIN keyword_counts kc ON kc.title_id = t.title_id
LEFT JOIN company_counts compc ON compc.title_id = t.title_id
GROUP BY t.production_year, t.kind
ORDER BY t.production_year DESC, t.kind
