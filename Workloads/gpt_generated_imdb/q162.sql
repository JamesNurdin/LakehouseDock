WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(r.rating) AS avg_rating,
    SUM(cc.cast_count) AS total_cast,
    SUM(ccmp.company_count) AS total_companies,
    SUM(kw.keyword_count) AS total_keywords
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings r ON t.id = r.movie_id
LEFT JOIN movie_cast_counts cc ON t.id = cc.movie_id
LEFT JOIN movie_company_counts ccmp ON t.id = ccmp.movie_id
LEFT JOIN movie_keyword_counts kw ON t.id = kw.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
