WITH title_kind AS (
    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
title_keywords AS (
    SELECT mk.movie_id AS title_id,
           COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
title_cast AS (
    SELECT ci.movie_id AS title_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
title_companies AS (
    SELECT mc.movie_id AS title_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT tk.kind,
       COUNT(DISTINCT tk.title_id) AS num_titles,
       AVG(tk.production_year) AS avg_production_year,
       SUM(COALESCE(tk2.keyword_cnt, 0)) AS total_keywords,
       SUM(COALESCE(tk3.cast_cnt, 0)) AS total_cast_members,
       SUM(COALESCE(tk4.company_cnt, 0)) AS total_production_companies
FROM title_kind tk
LEFT JOIN title_keywords tk2 ON tk.title_id = tk2.title_id
LEFT JOIN title_cast tk3 ON tk.title_id = tk3.title_id
LEFT JOIN title_companies tk4 ON tk.title_id = tk4.title_id
WHERE tk.production_year >= 2000
GROUP BY tk.kind
ORDER BY num_titles DESC
