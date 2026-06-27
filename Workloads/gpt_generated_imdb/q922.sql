WITH title_base AS (
    SELECT t.id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_agg AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    WHERE mi.info_type_id = 101
    GROUP BY mi.movie_id
),
budget_agg AS (
    SELECT mi_idx.movie_id,
           AVG(mi_idx.note) AS avg_budget_note
    FROM movie_info_idx mi_idx
    WHERE mi_idx.info_type_id = 201
    GROUP BY mi_idx.movie_id
)
SELECT tb.kind,
       tb.production_year,
       COUNT(*) AS title_cnt,
       AVG(COALESCE(ca.company_cnt, 0)) AS avg_companies_per_title,
       AVG(COALESCE(ka.keyword_cnt, 0)) AS avg_keywords_per_title,
       AVG(rg.avg_rating) AS avg_rating,
       AVG(bg.avg_budget_note) AS avg_budget_note
FROM title_base tb
LEFT JOIN company_agg ca ON ca.movie_id = tb.id
LEFT JOIN keyword_agg ka ON ka.movie_id = tb.id
LEFT JOIN rating_agg rg ON rg.movie_id = tb.id
LEFT JOIN budget_agg bg ON bg.movie_id = tb.id
GROUP BY tb.kind, tb.production_year
ORDER BY tb.kind, tb.production_year DESC
