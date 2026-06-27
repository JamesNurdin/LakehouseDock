WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
prod_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
)
SELECT
    m.production_year,
    m.kind,
    COUNT(*) AS movie_count,
    ROUND(AVG(COALESCE(cc.cast_count, 0)), 2) AS avg_cast_per_movie,
    ROUND(AVG(COALESCE(kc.keyword_count, 0)), 2) AS avg_keywords_per_movie,
    ROUND(AVG(COALESCE(pcc.prod_company_count, 0)), 2) AS avg_production_companies_per_movie
FROM movies m
LEFT JOIN cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN keyword_counts kc ON m.movie_id = kc.movie_id
LEFT JOIN prod_company_counts pcc ON m.movie_id = pcc.movie_id
GROUP BY
    m.production_year,
    m.kind
ORDER BY
    m.production_year DESC,
    m.kind
