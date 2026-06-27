WITH company_counts AS (
    SELECT mc.movie_id, COUNT(*) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id, COUNT(DISTINCT kw.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword kw ON kw.id = mk.keyword_id
    GROUP BY mk.movie_id
),
title_base AS (
    SELECT t.id AS title_id,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
)
SELECT
    tb.kind AS kind,
    tb.production_year AS production_year,
    COUNT(*) AS title_count,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_title,
    AVG(COALESCE(cc.company_cnt, 0)) AS avg_companies_per_title
FROM title_base tb
LEFT JOIN keyword_counts kc ON kc.movie_id = tb.title_id
LEFT JOIN company_counts cc ON cc.movie_id = tb.title_id
GROUP BY tb.kind, tb.production_year
ORDER BY title_count DESC
LIMIT 20
