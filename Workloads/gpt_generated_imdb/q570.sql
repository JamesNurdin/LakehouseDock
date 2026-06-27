WITH title_kinds AS (
    SELECT t.id,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
cast_counts AS (
    SELECT ci.movie_id AS title_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id AS title_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id AS title_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT tk.production_year,
       tk.kind,
       COUNT(*) AS num_titles,
       AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
       AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_title,
       AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_title
FROM title_kinds tk
LEFT JOIN cast_counts cc ON tk.id = cc.title_id
LEFT JOIN company_counts compc ON tk.id = compc.title_id
LEFT JOIN keyword_counts kc ON tk.id = kc.title_id
GROUP BY tk.production_year, tk.kind
ORDER BY tk.production_year DESC, tk.kind
