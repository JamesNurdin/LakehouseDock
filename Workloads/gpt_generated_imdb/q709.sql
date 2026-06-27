WITH rating_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(mi.info AS double) AS rating
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    JOIN kind_type kt ON kt.id = t.kind_id
    WHERE kt.kind = 'movie'
      AND it.info = 'rating'
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    r.title,
    r.production_year,
    r.rating,
    COALESCE(c.cast_count, 0) AS cast_count,
    COALESCE(comp.company_count, 0) AS company_count,
    COALESCE(k.keyword_count, 0) AS keyword_count
FROM rating_movies r
LEFT JOIN cast_counts c ON c.movie_id = r.movie_id
LEFT JOIN company_counts comp ON comp.movie_id = r.movie_id
LEFT JOIN keyword_counts k ON k.movie_id = r.movie_id
ORDER BY r.rating DESC
LIMIT 10
