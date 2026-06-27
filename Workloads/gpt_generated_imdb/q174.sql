WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
prod_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS movie_kind,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(pc.prod_company_count, 0) AS prod_company_count,
        COALESCE(mk.keywords, CAST(ARRAY[] AS array(varchar))) AS keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON t.id = cc.movie_id
    LEFT JOIN prod_company_counts pc ON t.id = pc.movie_id
    LEFT JOIN movie_keywords mk ON t.id = mk.movie_id
    WHERE t.production_year IS NOT NULL
)
SELECT
    movie_kind,
    production_year,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_size,
    SUM(prod_company_count) AS total_production_companies,
    ARRAY_DISTINCT(FLATTEN(ARRAY_AGG(keywords))) AS keywords_in_group
FROM movie_aggregates
GROUP BY movie_kind, production_year
ORDER BY movie_count DESC
LIMIT 20
