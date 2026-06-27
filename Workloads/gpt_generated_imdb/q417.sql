WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(TRY_CAST(mi.info AS double)) FILTER (WHERE it.info = 'rating') AS avg_rating,
        AVG(TRY_CAST(mi.info AS double)) FILTER (WHERE it.info = 'runtime') AS avg_runtime
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    company_count,
    keyword_count,
    avg_rating,
    avg_runtime
FROM movie_stats
WHERE avg_rating IS NOT NULL
ORDER BY avg_rating DESC
LIMIT 10
