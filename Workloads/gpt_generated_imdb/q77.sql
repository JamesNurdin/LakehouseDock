WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating' AND mi.info IS NOT NULL
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
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(r.rating) AS avg_rating,
    AVG(cc.cast_count) AS avg_cast_count,
    AVG(compc.company_count) AS avg_company_count,
    AVG(kc.keyword_count) AS avg_keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings r ON r.movie_id = t.id
LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
LEFT JOIN movie_company_counts compc ON compc.movie_id = t.id
LEFT JOIN movie_keyword_counts kc ON kc.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY avg_rating DESC
LIMIT 20
