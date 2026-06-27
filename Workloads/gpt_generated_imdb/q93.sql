WITH actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_cnt
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
title_stats AS (
    SELECT
        t.id AS title_id,
        t.title,
        CAST(t.production_year AS INTEGER) AS production_year,
        kt.kind,
        COALESCE(ac.distinct_actor_cnt, 0) AS actor_cnt,
        COALESCE(kc.distinct_keyword_cnt, 0) AS keyword_cnt,
        COALESCE(cc.distinct_company_cnt, 0) AS company_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN actor_counts ac ON t.id = ac.movie_id
    LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
    LEFT JOIN company_counts cc ON t.id = cc.movie_id
    WHERE t.production_year IS NOT NULL
      AND CAST(t.production_year AS INTEGER) >= 2000
)
SELECT
    production_year,
    kind,
    COUNT(*) AS num_titles,
    SUM(actor_cnt) AS total_actors,
    AVG(actor_cnt) AS avg_actors_per_title,
    SUM(keyword_cnt) AS total_keywords,
    AVG(keyword_cnt) AS avg_keywords_per_title,
    SUM(company_cnt) AS total_companies,
    AVG(company_cnt) AS avg_companies_per_title
FROM title_stats
GROUP BY production_year, kind
ORDER BY production_year DESC, kind
LIMIT 100
