WITH movie_ratings AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
production_company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    k.kind AS genre,
    t.production_year,
    COUNT(*) AS movie_count,
    AVG(r.rating) AS avg_rating,
    AVG(cc.cast_count) AS avg_cast_size,
    AVG(pc.company_count) AS avg_production_company_count,
    AVG(kc.keyword_count) AS avg_keyword_count
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN movie_ratings r ON t.id = r.movie_id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN production_company_counts pc ON t.id = pc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY k.kind, t.production_year
ORDER BY k.kind, t.production_year
