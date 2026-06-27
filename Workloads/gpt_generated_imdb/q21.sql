WITH movie_aggregates AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT kw.id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    title,
    production_year,
    kind,
    cast_count,
    keyword_count,
    info_type_count,
    CAST(keyword_count AS double) / NULLIF(cast_count, 0) AS keywords_per_cast
FROM movie_aggregates
WHERE cast_count > 0
ORDER BY keyword_count DESC, cast_count DESC
LIMIT 10
