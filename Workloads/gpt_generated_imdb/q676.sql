WITH title_kind AS (
    SELECT t.id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    tk.production_year,
    tk.kind,
    COUNT(*) AS title_cnt,
    COALESCE(SUM(ca.cast_cnt), 0) AS total_cast_members,
    COALESCE(SUM(coa.comp_cnt), 0) AS total_companies,
    COALESCE(SUM(ka.kw_cnt), 0) AS total_keywords,
    ROUND(COALESCE(SUM(ca.cast_cnt), 0) / NULLIF(COUNT(*), 0), 2) AS avg_cast_per_title,
    ROUND(COALESCE(SUM(coa.comp_cnt), 0) / NULLIF(COUNT(*), 0), 2) AS avg_companies_per_title,
    ROUND(COALESCE(SUM(ka.kw_cnt), 0) / NULLIF(COUNT(*), 0), 2) AS avg_keywords_per_title
FROM title_kind tk
LEFT JOIN cast_agg ca   ON ca.movie_id = tk.id   -- cast_info.movie_id = title.id
LEFT JOIN company_agg coa ON coa.movie_id = tk.id   -- movie_companies.movie_id = title.id
LEFT JOIN keyword_agg ka  ON ka.movie_id = tk.id   -- movie_keyword.movie_id = title.id
GROUP BY tk.production_year, tk.kind
ORDER BY tk.production_year DESC, tk.kind
