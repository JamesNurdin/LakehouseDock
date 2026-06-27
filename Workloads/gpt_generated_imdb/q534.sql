WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS DOUBLE) AS rating
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
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        mr.rating,
        COALESCE(mcc.cast_count, 0) AS cast_count,
        COALESCE(mcompc.company_count, 0) AS company_count,
        COALESCE(mkwc.keyword_count, 0) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_ratings mr ON mr.movie_id = t.id
    LEFT JOIN movie_cast_counts mcc ON mcc.movie_id = t.id
    LEFT JOIN movie_company_counts mcompc ON mcompc.movie_id = t.id
    LEFT JOIN movie_keyword_counts mkwc ON mkwc.movie_id = t.id
    WHERE kt.kind = 'movie' AND t.production_year IS NOT NULL
)
SELECT
    production_year,
    COUNT(*) AS num_movies,
    AVG(rating) AS avg_rating,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie
FROM movie_details
GROUP BY production_year
ORDER BY production_year
