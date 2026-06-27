WITH title_base AS (
    SELECT t.id AS title_id,
           t.production_year,
           kt.kind AS kind_name
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
title_counts AS (
    SELECT production_year,
           kind_name,
           COUNT(*) AS title_count
    FROM title_base
    GROUP BY production_year, kind_name
),
cast_metrics AS (
    SELECT tb.production_year,
           tb.kind_name,
           COUNT(DISTINCT ci.person_id) AS distinct_cast_members,
           AVG(cpt.cast_member_count) AS avg_cast_per_title
    FROM title_base tb
    LEFT JOIN cast_info ci ON ci.movie_id = tb.title_id
    LEFT JOIN (
        SELECT movie_id,
               COUNT(DISTINCT person_id) AS cast_member_count
        FROM cast_info
        GROUP BY movie_id
    ) cpt ON cpt.movie_id = tb.title_id
    GROUP BY tb.production_year, tb.kind_name
),
company_metrics AS (
    SELECT tb.production_year,
           tb.kind_name,
           COUNT(DISTINCT cn.id) AS distinct_companies,
           AVG(cpt.company_count) AS avg_companies_per_title
    FROM title_base tb
    LEFT JOIN movie_companies mc ON mc.movie_id = tb.title_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN (
        SELECT mc.movie_id,
               COUNT(DISTINCT cn.id) AS company_count
        FROM movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        GROUP BY mc.movie_id
    ) cpt ON cpt.movie_id = tb.title_id
    GROUP BY tb.production_year, tb.kind_name
),
keyword_metrics AS (
    SELECT tb.production_year,
           tb.kind_name,
           COUNT(DISTINCT mk.keyword_id) AS distinct_keywords,
           AVG(kpt.keyword_count) AS avg_keywords_per_title
    FROM title_base tb
    LEFT JOIN movie_keyword mk ON mk.movie_id = tb.title_id
    LEFT JOIN (
        SELECT movie_id,
               COUNT(DISTINCT keyword_id) AS keyword_count
        FROM movie_keyword
        GROUP BY movie_id
    ) kpt ON kpt.movie_id = tb.title_id
    GROUP BY tb.production_year, tb.kind_name
)
SELECT
    tc.production_year,
    tc.kind_name,
    tc.title_count,
    cm.distinct_cast_members,
    cm.avg_cast_per_title,
    com.distinct_companies,
    com.avg_companies_per_title,
    km.distinct_keywords,
    km.avg_keywords_per_title
FROM title_counts tc
LEFT JOIN cast_metrics cm   ON cm.production_year = tc.production_year AND cm.kind_name = tc.kind_name
LEFT JOIN company_metrics com ON com.production_year = tc.production_year AND com.kind_name = tc.kind_name
LEFT JOIN keyword_metrics km  ON km.production_year = tc.production_year AND km.kind_name = tc.kind_name
ORDER BY tc.production_year DESC, tc.kind_name
