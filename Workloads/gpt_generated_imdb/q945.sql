WITH keyword_counts AS (
    SELECT
        mk.movie_id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id AS title_id,
        COUNT(DISTINCT mc.company_id) AS comp_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
titles_with_plot AS (
    SELECT DISTINCT
        mi.movie_id AS title_id
    FROM movie_info mi
    JOIN info_type it
        ON it.id = mi.info_type_id
    WHERE it.info = 'Plot'
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS title_count,
    AVG(COALESCE(kc.kw_count, 0)) AS avg_keywords,
    AVG(COALESCE(cc.comp_count, 0)) AS avg_companies,
    AVG(CASE WHEN tp.title_id IS NOT NULL THEN 1 ELSE 0 END) AS pct_titles_with_plot
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN keyword_counts kc
    ON kc.title_id = t.id
LEFT JOIN company_counts cc
    ON cc.title_id = t.id
LEFT JOIN titles_with_plot tp
    ON tp.title_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
