WITH title_kind AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.kind
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id AS title_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    tk.kind,
    tk.production_year,
    COUNT(tk.title_id) AS num_titles,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_title
FROM title_kind tk
LEFT JOIN cast_counts cc ON tk.title_id = cc.title_id
LEFT JOIN company_counts compc ON tk.title_id = compc.title_id
GROUP BY tk.kind, tk.production_year
ORDER BY tk.kind, tk.production_year
