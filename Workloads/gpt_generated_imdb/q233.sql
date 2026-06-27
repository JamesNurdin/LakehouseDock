WITH movie_summary AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count,
        COUNT(DISTINCT mi_idx.info_type_id) AS info_idx_type_count
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = t.id
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
)
SELECT
    id,
    title,
    production_year,
    kind,
    cast_count,
    company_count,
    info_type_count,
    info_idx_type_count
FROM movie_summary
ORDER BY cast_count DESC
LIMIT 20
