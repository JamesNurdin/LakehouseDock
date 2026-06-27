WITH company_counts AS (
    SELECT mc.movie_id AS title_id,
           COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id AS title_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
aggregated AS (
    SELECT
        kt.kind AS kind,
        t.production_year,
        COUNT(DISTINCT t.id) AS title_cnt,
        AVG(COALESCE(cc.company_cnt, 0)) AS avg_companies_per_title,
        AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_title
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN company_counts cc ON t.id = cc.title_id
    LEFT JOIN keyword_counts kc ON t.id = kc.title_id
    WHERE t.production_year IS NOT NULL
    GROUP BY kt.kind, t.production_year
)
SELECT
    kind,
    production_year,
    title_cnt,
    avg_companies_per_title,
    avg_keywords_per_title,
    ROW_NUMBER() OVER (PARTITION BY kind ORDER BY title_cnt DESC) AS rank_in_kind
FROM aggregated
ORDER BY kind, rank_in_kind
