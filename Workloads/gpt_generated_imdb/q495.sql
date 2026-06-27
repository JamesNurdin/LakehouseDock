WITH cast_counts AS (
    SELECT
        ci.movie_id AS title_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
prod_company_counts AS (
    SELECT
        mc.movie_id AS title_id,
        COUNT(DISTINCT cn.id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
metrics AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(*) AS num_titles,
        AVG(cc.cast_count) AS avg_cast_per_title,
        AVG(pc.prod_company_count) AS avg_prod_companies_per_title
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON cc.title_id = t.id
    LEFT JOIN prod_company_counts pc ON pc.title_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind, k.keyword
),
keyword_rank AS (
    SELECT
        production_year,
        kind,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movie_cnt DESC) AS rn
    FROM keyword_counts
)
SELECT
    m.production_year,
    m.kind,
    m.num_titles,
    m.avg_cast_per_title,
    m.avg_prod_companies_per_title,
    kr.keyword AS top_keyword,
    kr.movie_cnt AS top_keyword_movie_count
FROM metrics m
LEFT JOIN keyword_rank kr
    ON kr.production_year = m.production_year
   AND kr.kind = m.kind
   AND kr.rn = 1
ORDER BY m.production_year DESC, m.kind
