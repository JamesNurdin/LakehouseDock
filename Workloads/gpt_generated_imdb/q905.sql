WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT k.id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        CAST(MAX(CASE WHEN it.info = 'runtime' THEN mi.info END) AS integer) AS runtime_minutes
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    cast_count,
    keyword_count,
    company_count,
    runtime_minutes
FROM movie_stats
ORDER BY cast_count DESC, keyword_count DESC
LIMIT 20
