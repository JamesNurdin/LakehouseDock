WITH cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        cast_info ci
        JOIN title t ON ci.movie_id = t.id
    GROUP BY
        t.id
),
production_company_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM
        movie_companies mc
        JOIN title t ON mc.movie_id = t.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE
        ct.kind = 'production'
    GROUP BY
        t.id
),
keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
        JOIN title t ON mk.movie_id = t.id
    GROUP BY
        t.id
),
rating_info AS (
    SELECT
        t.id AS movie_id,
        AVG(TRY_CAST(mi.info AS double)) AS avg_rating
    FROM
        movie_info mi
        JOIN title t ON mi.movie_id = t.id
        JOIN info_type it ON mi.info_type_id = it.id
    WHERE
        it.info = 'rating'
    GROUP BY
        t.id
),
movie_details AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind AS kind_name,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(pc.production_company_count, 0) AS production_company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        ri.avg_rating
    FROM
        title t
        JOIN kind_type kt ON t.kind_id = kt.id
        LEFT JOIN cast_counts cc ON t.id = cc.movie_id
        LEFT JOIN production_company_counts pc ON t.id = pc.movie_id
        LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
        LEFT JOIN rating_info ri ON t.id = ri.movie_id
    WHERE
        kt.kind = 'movie'
)
SELECT
    md.title,
    md.production_year,
    md.cast_count,
    md.production_company_count,
    md.keyword_count,
    md.avg_rating,
    RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS cast_rank_within_year
FROM
    movie_details md
ORDER BY
    md.cast_count DESC
LIMIT 20
