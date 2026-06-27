WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN it.info = 'runtime' THEN mi.info END) AS runtime_minutes,
        MAX(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS BIGINT) END) AS budget_usd
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN name n
        ON ci.person_id = n.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    cast_count,
    production_company_count,
    keyword_count,
    runtime_minutes,
    budget_usd
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 10
