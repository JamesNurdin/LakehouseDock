WITH movie_ratings AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        CAST(mi.info AS double) AS rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND t.production_year >= 2000
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_production_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
)
SELECT
    mr.title,
    mr.production_year,
    mr.kind,
    mr.rating,
    COALESCE(mcc.cast_count, 0) AS cast_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(mpc.production_company_count, 0) AS production_company_count
FROM movie_ratings mr
LEFT JOIN movie_cast_counts mcc ON mr.movie_id = mcc.movie_id
LEFT JOIN movie_keyword_counts mkc ON mr.movie_id = mkc.movie_id
LEFT JOIN movie_production_company_counts mpc ON mr.movie_id = mpc.movie_id
ORDER BY mr.rating DESC
LIMIT 10
