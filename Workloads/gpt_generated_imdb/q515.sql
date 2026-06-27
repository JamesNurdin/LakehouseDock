WITH title_kind AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_info_flags AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN mi.info_type_id = 101 THEN 1 ELSE 0 END) AS has_info_101
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    tk.kind,
    CAST(tk.production_year AS integer) AS prod_year,
    COUNT(DISTINCT tk.title_id) AS title_cnt,
    AVG(tk.production_year) AS avg_production_year,
    AVG(COALESCE(mcc.distinct_company_cnt, 0)) AS avg_distinct_companies,
    SUM(COALESCE(mif.has_info_101, 0)) AS titles_with_info_101
FROM title_kind tk
LEFT JOIN movie_company_counts mcc
    ON mcc.movie_id = tk.title_id
LEFT JOIN movie_info_flags mif
    ON mif.movie_id = tk.title_id
WHERE tk.production_year IS NOT NULL
GROUP BY tk.kind, CAST(tk.production_year AS integer)
ORDER BY tk.kind, prod_year DESC
