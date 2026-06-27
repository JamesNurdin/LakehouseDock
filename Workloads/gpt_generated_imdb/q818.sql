WITH movie_data AS (
    SELECT DISTINCT
        t.id AS title_id,
        t.production_year,
        mi.info_type_id,
        mk.keyword_id
    FROM title t
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.kind_id = 1
)
SELECT
    production_year,
    COUNT(DISTINCT title_id) AS movie_count,
    COUNT(DISTINCT keyword_id) AS distinct_keyword_count,
    COUNT(DISTINCT CASE WHEN info_type_id = 12 THEN title_id END) * 1.0 / NULLIF(COUNT(DISTINCT title_id), 0) AS proportion_info_type_12
FROM movie_data
GROUP BY production_year
ORDER BY production_year
