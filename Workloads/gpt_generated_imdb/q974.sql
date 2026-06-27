WITH
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
    ),
    rating_agg AS (
        SELECT
            mi.movie_id,
            AVG(CAST(mi.info AS DOUBLE)) AS avg_rating,
            COUNT(*) AS rating_count
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating' AND mi.info IS NOT NULL
        GROUP BY mi.movie_id
    )
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(pc.prod_company_count, 0) AS prod_company_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.rating_count, 0) AS rating_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN prod_company_counts pc ON pc.movie_id = t.id
LEFT JOIN rating_agg r ON r.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC, keyword_count DESC
LIMIT 10
