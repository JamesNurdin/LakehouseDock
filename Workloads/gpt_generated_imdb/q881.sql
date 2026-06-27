/*
  Analytical query: number of titles, total/average cast members, production companies, and keywords
  grouped by production year and title kind (e.g., movie, TV series).
*/
WITH title_kind AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
production_company_counts AS (
    SELECT
        mc.movie_id AS title_id,
        COUNT(DISTINCT cn.id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    tk.production_year,
    tk.kind_name,
    COUNT(DISTINCT tk.title_id) AS total_titles,
    COALESCE(SUM(cc.cast_member_count), 0) AS total_cast_members,
    COALESCE(AVG(cc.cast_member_count), 0) AS avg_cast_per_title,
    COALESCE(SUM(pcc.production_company_count), 0) AS total_production_companies,
    COALESCE(SUM(kc.keyword_count), 0) AS total_keywords
FROM title_kind tk
LEFT JOIN cast_counts cc ON tk.title_id = cc.title_id
LEFT JOIN production_company_counts pcc ON tk.title_id = pcc.title_id
LEFT JOIN keyword_counts kc ON tk.title_id = kc.title_id
GROUP BY tk.production_year, tk.kind_name
ORDER BY tk.production_year DESC, tk.kind_name
