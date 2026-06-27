WITH title_kind AS (
    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
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
),
info_type_per_title AS (
    SELECT mi.movie_id AS title_id, mi.info_type_id
    FROM movie_info mi
    UNION
    SELECT mii.movie_id AS title_id, mii.info_type_id
    FROM movie_info_idx mii
),
info_counts AS (
    SELECT title_id,
           COUNT(DISTINCT info_type_id) AS info_type_count
    FROM info_type_per_title
    GROUP BY title_id
)
SELECT tk.kind,
       COUNT(DISTINCT tk.title_id) AS num_titles,
       AVG(tk.production_year) AS avg_production_year,
       SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
       SUM(COALESCE(ccc.company_count, 0)) AS total_companies,
       SUM(COALESCE(kc.keyword_count, 0)) AS total_keywords,
       SUM(COALESCE(ic.info_type_count, 0)) AS total_info_types
FROM title_kind tk
LEFT JOIN cast_counts cc ON tk.title_id = cc.title_id
LEFT JOIN company_counts ccc ON tk.title_id = ccc.title_id
LEFT JOIN keyword_counts kc ON tk.title_id = kc.title_id
LEFT JOIN info_counts ic ON tk.title_id = ic.title_id
GROUP BY tk.kind
ORDER BY num_titles DESC
