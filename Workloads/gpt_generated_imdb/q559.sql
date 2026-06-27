WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(r.rating) AS avg_rating,
        AVG(cc.cast_count) AS avg_cast_per_movie
    FROM company_name cn
    JOIN movie_companies mc ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    LEFT JOIN movie_cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN movie_ratings r ON r.movie_id = t.id
    WHERE ct.kind = 'production company'
      AND t.production_year >= 2000
    GROUP BY cn.id, cn.name
)
SELECT
    company_name,
    movie_count,
    avg_rating,
    avg_cast_per_movie
FROM company_movie_stats
ORDER BY movie_count DESC
LIMIT 10
